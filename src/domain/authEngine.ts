import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import {
  CreateUserInput,
  ErpState,
  LoginInput,
  LoginResponse,
  PublicUser,
  UserAccount,
  UserRole,
} from '../types/erp';
import { AppDomainError } from '../utils/errors';

const SCRYPT_KEYLEN = 64;
const DEFAULT_SESSION_TTL_MS =
  (Number(process.env.ERP_SESSION_TTL_HOURS) || 24) * 60 * 60 * 1000;

export interface ActiveSession {
  token: string;
  userId: string;
  createdAt: number;
  expiresAt: number;
}

/**
 * Hashes a plaintext password using Node's cryptographic scrypt KDF with a 16-byte random salt.
 * Never stores plaintext passwords.
 */
export function hashPassword(plainPassword: string): string {
  const salt = randomBytes(16).toString('hex');
  const derivedKey = scryptSync(plainPassword, salt, SCRYPT_KEYLEN).toString(
    'hex'
  );
  return `scrypt$${salt}$${derivedKey}`;
}

/**
 * Verifies a plaintext password against a stored scrypt hash using constant-time comparison.
 */
export function verifyPassword(
  plainPassword: string,
  storedHash: string
): boolean {
  if (!storedHash || typeof storedHash !== 'string') return false;
  const parts = storedHash.split('$');
  if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
  const [, salt, hashHex] = parts;
  if (!salt || !hashHex) return false;

  try {
    const expectedBuffer = Buffer.from(hashHex, 'hex');
    const actualBuffer = scryptSync(plainPassword, salt, SCRYPT_KEYLEN);
    if (expectedBuffer.length !== actualBuffer.length) return false;
    return timingSafeEqual(expectedBuffer, actualBuffer);
  } catch {
    return false;
  }
}

/**
 * Strips sensitive fields (passwordHash) before returning user records to clients.
 */
export function toPublicUser(user: UserAccount): PublicUser {
  return {
    id: user.id,
    username: user.username,
    displayName: user.displayName,
    role: user.role,
    isActive: user.isActive,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

/**
 * Ensures the ERP state has a valid users array and provisions the initial administrator
 * account securely if no active admin exists.
 */
export function ensureInitialAdminProvisioned(
  state: ErpState,
  nowIso: string = new Date().toISOString()
): UserAccount[] {
  if (!Array.isArray(state.users)) {
    state.users = [];
  }

  const hasActiveAdmin = state.users.some(
    (u) => u.role === 'admin' && u.isActive
  );
  if (hasActiveAdmin) {
    return state.users;
  }

  const configuredUsername = (
    process.env.ERP_ADMIN_USERNAME || 'admin'
  )
    .trim()
    .toLowerCase();
  const configuredPassword =
    process.env.ERP_ADMIN_PASSWORD && process.env.ERP_ADMIN_PASSWORD.trim()
      ? process.env.ERP_ADMIN_PASSWORD.trim()
      : 'Admin@12345';

  const existingAdmin = state.users.find(
    (u) => u.username.toLowerCase() === configuredUsername
  );

  if (existingAdmin) {
    existingAdmin.role = 'admin';
    existingAdmin.isActive = true;
    existingAdmin.updatedAt = nowIso;
    return state.users;
  }

  const initialAdmin: UserAccount = {
    id: 'usr_admin_initial',
    username: configuredUsername,
    displayName: 'Store Administrator',
    role: 'admin',
    passwordHash: hashPassword(configuredPassword),
    isActive: true,
    createdAt: nowIso,
    updatedAt: nowIso,
  };

  state.users.unshift(initialAdmin);
  return state.users;
}

/**
 * Authenticates a user with pre-registered credentials and issues a session token.
 */
export function authenticateUser(
  state: ErpState,
  sessions: Map<string, ActiveSession>,
  input: LoginInput,
  nowMs: number = Date.now()
): LoginResponse {
  ensureInitialAdminProvisioned(state);

  const rawUsername =
    typeof input?.username === 'string' ? input.username.trim() : '';
  const rawPassword =
    typeof input?.password === 'string' ? input.password : '';

  if (!rawUsername) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Username or email is required.',
      { field: 'username' }
    );
  }
  if (!rawPassword || !rawPassword.trim()) {
    throw new AppDomainError('VALIDATION_ERROR', 'Password is required.', {
      field: 'password',
    });
  }

  const normalizedUsername = rawUsername.toLowerCase();
  const user = state.users!.find(
    (u) => u.username.toLowerCase() === normalizedUsername
  );

  if (!user || !verifyPassword(rawPassword, user.passwordHash)) {
    throw new AppDomainError(
      'INVALID_CREDENTIALS',
      'Invalid username or password. Please verify your pre-registered credentials.'
    );
  }

  if (!user.isActive) {
    throw new AppDomainError(
      'ACCOUNT_DEACTIVATED',
      'This user account has been deactivated by an administrator.'
    );
  }

  const token = randomBytes(32).toString('hex');
  sessions.set(token, {
    token,
    userId: user.id,
    createdAt: nowMs,
    expiresAt: nowMs + DEFAULT_SESSION_TTL_MS,
  });

  return {
    token,
    user: toPublicUser(user),
  };
}

/**
 * Resolves and validates an active session token to its current active UserAccount.
 */
export function verifySessionToken(
  state: ErpState,
  sessions: Map<string, ActiveSession>,
  token: string | undefined | null,
  nowMs: number = Date.now()
): UserAccount {
  ensureInitialAdminProvisioned(state);

  if (!token || typeof token !== 'string' || !token.trim()) {
    throw new AppDomainError(
      'UNAUTHORIZED',
      'Authentication required. Please log in with your pre-registered credentials.'
    );
  }

  const session = sessions.get(token.trim());
  if (!session) {
    throw new AppDomainError(
      'UNAUTHORIZED',
      'Your session is invalid or has expired. Please log in again.'
    );
  }

  if (nowMs > session.expiresAt) {
    sessions.delete(token.trim());
    throw new AppDomainError(
      'UNAUTHORIZED',
      'Your session has expired. Please log in again.'
    );
  }

  const user = state.users!.find((u) => u.id === session.userId);
  if (!user) {
    sessions.delete(token.trim());
    throw new AppDomainError(
      'UNAUTHORIZED',
      'User account no longer exists. Please log in again.'
    );
  }

  if (!user.isActive) {
    sessions.delete(token.trim());
    throw new AppDomainError(
      'ACCOUNT_DEACTIVATED',
      'Your account has been deactivated by an administrator.'
    );
  }

  return user;
}

/**
 * Asserts that the acting user has administrator privileges.
 */
export function assertAdminRole(actor: UserAccount): void {
  if (actor.role !== 'admin') {
    throw new AppDomainError(
      'FORBIDDEN',
      'Administrator privileges are required for this operation.'
    );
  }
}

/**
 * Creates a new pre-registered user account (Admin only).
 */
export function createAuthorizedUser(
  state: ErpState,
  actor: UserAccount,
  input: CreateUserInput,
  nowIso: string = new Date().toISOString()
): PublicUser {
  assertAdminRole(actor);
  ensureInitialAdminProvisioned(state, nowIso);

  const username =
    typeof input?.username === 'string'
      ? input.username.trim().toLowerCase()
      : '';
  if (username.length < 3 || username.length > 60) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Username must be between 3 and 60 characters.',
      { field: 'username' }
    );
  }

  const password =
    typeof input?.password === 'string' ? input.password.trim() : '';
  if (password.length < 6 || password.length > 128) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Password must be at least 6 characters.',
      { field: 'password' }
    );
  }

  const role: UserRole =
    input.role === 'admin' || input.role === 'staff' ? input.role : 'staff';

  const displayName =
    typeof input.displayName === 'string' && input.displayName.trim()
      ? input.displayName.trim().slice(0, 80)
      : username;

  const duplicate = state.users!.some(
    (u) => u.username.toLowerCase() === username
  );
  if (duplicate) {
    throw new AppDomainError(
      'DUPLICATE_RECORD',
      `A user account with username "${username}" already exists.`,
      { field: 'username' }
    );
  }

  const newUser: UserAccount = {
    id: `usr_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    username,
    displayName,
    role,
    passwordHash: hashPassword(password),
    isActive: true,
    createdAt: nowIso,
    updatedAt: nowIso,
  };

  state.users!.push(newUser);
  return toPublicUser(newUser);
}

/**
 * Counts how many active administrator accounts currently exist.
 */
export function countActiveAdmins(users: UserAccount[]): number {
  return users.filter((u) => u.role === 'admin' && u.isActive).length;
}

/**
 * Activates or deactivates a user account while protecting the last active administrator.
 */
export function setAuthorizedUserStatus(
  state: ErpState,
  sessions: Map<string, ActiveSession>,
  actor: UserAccount,
  targetUserId: string,
  isActive: boolean,
  nowIso: string = new Date().toISOString()
): PublicUser {
  assertAdminRole(actor);
  ensureInitialAdminProvisioned(state, nowIso);

  const target = state.users!.find((u) => u.id === targetUserId);
  if (!target) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `User account "${targetUserId}" was not found.`,
      { recordId: targetUserId }
    );
  }

  if (!isActive && target.role === 'admin' && target.isActive) {
    const activeAdmins = countActiveAdmins(state.users!);
    if (activeAdmins <= 1) {
      throw new AppDomainError(
        'LAST_ADMIN_PROTECTION',
        'Cannot deactivate the last active administrator account.'
      );
    }
  }

  target.isActive = Boolean(isActive);
  target.updatedAt = nowIso;

  // Revoke active sessions if user was deactivated
  if (!target.isActive) {
    for (const [tok, sess] of sessions.entries()) {
      if (sess.userId === target.id) {
        sessions.delete(tok);
      }
    }
  }

  return toPublicUser(target);
}

/**
 * Permanently removes a user account while strictly protecting the last active administrator.
 */
export function deleteAuthorizedUser(
  state: ErpState,
  sessions: Map<string, ActiveSession>,
  actor: UserAccount,
  targetUserId: string
): string {
  assertAdminRole(actor);
  ensureInitialAdminProvisioned(state);

  const index = state.users!.findIndex((u) => u.id === targetUserId);
  if (index === -1) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `User account "${targetUserId}" was not found.`,
      { recordId: targetUserId }
    );
  }

  const target = state.users![index];
  if (target.role === 'admin' && target.isActive) {
    const activeAdmins = countActiveAdmins(state.users!);
    if (activeAdmins <= 1) {
      throw new AppDomainError(
        'LAST_ADMIN_PROTECTION',
        'Cannot delete the last active administrator account.'
      );
    }
  }

  state.users!.splice(index, 1);

  for (const [tok, sess] of sessions.entries()) {
    if (sess.userId === target.id) {
      sessions.delete(tok);
    }
  }

  return target.id;
}
