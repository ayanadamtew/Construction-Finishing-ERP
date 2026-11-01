import dotenv from 'dotenv';
import express, { NextFunction, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import {
  ActiveSession,
  assertAdminRole,
  authenticateUser,
  createAuthorizedUser,
  deleteAuthorizedUser,
  ensureInitialAdminProvisioned,
  setAuthorizedUserStatus,
  toPublicUser,
  verifySessionToken,
} from './src/domain/authEngine';
import {
  calculateStoreSummary,
  createCategory,
  createInitialErpState,
  deleteCategory,
  deleteMaterial,
  ensureCategoriesInitialized,
  recordMultiItemSale,
  recordStockAudit,
  recordStockIn,
  registerMaterial,
  reverseSaleTransaction,
  reverseStockAuditRecord,
  reverseStockInRecord,
  setMaterialArchivedStatus,
  updateMaterialMetadata,
} from './src/domain/inventoryEngine';
import {
  ArchiveMaterialInput,
  CreateAuditInput,
  CreateCategoryInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateStockInInput,
  CreateUserInput,
  ErpState,
  LoginInput,
  ReverseTransactionInput,
  UpdateMaterialInput,
  UpdateUserStatusInput,
  UserAccount,
} from './src/types/erp';
import { AppDomainError } from './src/utils/errors';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = Number(process.env.PORT) || 3000;
const DATA_FILE_PATH = path.resolve(
  __dirname,
  process.env.DATA_FILE_PATH || './data/erp-store.json'
);

interface AuthenticatedRequest extends Request {
  authUser?: UserAccount;
  authToken?: string;
}

/**
 * Loads or initializes the persistent ERP state on disk per docs/ARCHITECTURE.md Section 10.
 */
function loadOrInitializeStore(): ErpState {
  try {
    if (fs.existsSync(DATA_FILE_PATH)) {
      const raw = fs.readFileSync(DATA_FILE_PATH, 'utf-8');
      const parsed = JSON.parse(raw) as ErpState;
      if (parsed && Array.isArray(parsed.materials)) {
        ensureCategoriesInitialized(parsed);
        ensureInitialAdminProvisioned(parsed);
        parsed.summary = calculateStoreSummary(
          parsed.materials,
          parsed.sales ?? []
        );
        return parsed;
      }
    }
  } catch (err) {
    console.warn('Initializing fresh ERP store file:', err);
  }

  const initialState = createInitialErpState();
  ensureCategoriesInitialized(initialState);
  ensureInitialAdminProvisioned(initialState);
  saveStoreAtomically(initialState);
  return initialState;
}

/**
 * Writes the ERP state atomically via a temporary file rename so partial writes never corrupt state.
 */
export function saveStoreAtomically(state: ErpState): void {
  const dir = path.dirname(DATA_FILE_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const tempPath = `${DATA_FILE_PATH}.tmp`;
  fs.writeFileSync(tempPath, JSON.stringify(state, null, 2), 'utf-8');
  fs.renameSync(tempPath, DATA_FILE_PATH);
}

function extractBearerToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header || typeof header !== 'string') return null;
  const parts = header.trim().split(/\s+/);
  if (parts.length === 2 && parts[0].toLowerCase() === 'bearer') {
    return parts[1];
  }
  return null;
}

/**
 * Sanitizes ErpState before sending over HTTP so password hashes are never exposed.
 */
function toClientErpState(state: ErpState): Omit<ErpState, 'users'> {
  const { users: _users, ...rest } = state;
  return {
    ...rest,
    categories: ensureCategoriesInitialized(state),
    summary: calculateStoreSummary(state.materials, state.sales),
  };
}

/**
 * Creates an Express application wired with all approved /api/* routes,
 * pre-registered credential authentication, role-based access control,
 * safe deletion/archiving, transaction reversals, and centralized error handling.
 */
export function createErpApiApp(
  initialState?: ErpState,
  persistFn: (state: ErpState) => void = saveStoreAtomically
): {
  app: express.Express;
  getState: () => ErpState;
  sessions: Map<string, ActiveSession>;
} {
  const app = express();
  const storeState: ErpState = initialState ?? loadOrInitializeStore();
  ensureCategoriesInitialized(storeState);
  ensureInitialAdminProvisioned(storeState);

  const sessions = new Map<string, ActiveSession>();

  // Enforce 100kb payload limit per SEC-003
  app.use(express.json({ limit: '100kb' }));

  // ============================================================================
  // Authentication & Session Endpoints (Public Login + Protected Session Routes)
  // ============================================================================

  app.post(
    '/api/auth/login',
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as LoginInput;
        const result = authenticateUser(storeState, sessions, body);
        persistFn(storeState);
        res.status(200).json(result);
      } catch (err) {
        next(err);
      }
    }
  );

  // Authentication Middleware for all subsequent /api/* routes
  const requireAuth = (
    req: AuthenticatedRequest,
    _res: Response,
    next: NextFunction
  ) => {
    try {
      const token = extractBearerToken(req);
      const user = verifySessionToken(storeState, sessions, token);
      req.authUser = user;
      req.authToken = token ?? undefined;
      next();
    } catch (err) {
      next(err);
    }
  };

  app.get('/api/auth/me', requireAuth, (req: AuthenticatedRequest, res: Response) => {
    res.status(200).json({
      user: toPublicUser(req.authUser!),
    });
  });

  app.post(
    '/api/auth/logout',
    requireAuth,
    (req: AuthenticatedRequest, res: Response) => {
      if (req.authToken) {
        sessions.delete(req.authToken);
      }
      res.status(200).json({ success: true });
    }
  );

  // ============================================================================
  // Administrator User Management Routes (/api/users)
  // ============================================================================

  app.get(
    '/api/users',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        assertAdminRole(req.authUser!);
        ensureInitialAdminProvisioned(storeState);
        res.status(200).json({
          users: storeState.users!.map(toPublicUser),
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.post(
    '/api/users',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateUserInput;
        const user = createAuthorizedUser(storeState, req.authUser!, body);
        persistFn(storeState);
        res.status(201).json({
          user,
          users: storeState.users!.map(toPublicUser),
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.patch(
    '/api/users/:id/status',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const targetId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as UpdateUserStatusInput;
        if (typeof body.isActive !== 'boolean') {
          throw new AppDomainError(
            'VALIDATION_ERROR',
            'isActive boolean flag is required.',
            { field: 'isActive' }
          );
        }
        const user = setAuthorizedUserStatus(
          storeState,
          sessions,
          req.authUser!,
          targetId,
          body.isActive
        );
        persistFn(storeState);
        res.status(200).json({
          user,
          users: storeState.users!.map(toPublicUser),
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.delete(
    '/api/users/:id',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const targetId = String(req.params.id ?? '');
        const deletedUserId = deleteAuthorizedUser(
          storeState,
          sessions,
          req.authUser!,
          targetId
        );
        persistFn(storeState);
        res.status(200).json({
          deletedUserId,
          users: storeState.users!.map(toPublicUser),
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // ============================================================================
  // Approved ERP Store & Transaction Routes (Protected by requireAuth)
  // ============================================================================

  // 1. GET /api/state (FR-005, FR-020, FR-021)
  app.get('/api/state', requireAuth, (_req: Request, res: Response) => {
    res.status(200).json(toClientErpState(storeState));
  });

  // 2. POST /api/materials (FR-001, FR-002, BR-005)
  app.post(
    '/api/materials',
    requireAuth,
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateMaterialInput;
        const material = registerMaterial(storeState, body);
        persistFn(storeState);
        res.status(201).json({
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 3. PATCH /api/materials/:id (FR-003, FR-004, BR-001)
  app.patch(
    '/api/materials/:id',
    requireAuth,
    (req: Request, res: Response, next: NextFunction) => {
      try {
        const materialId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as UpdateMaterialInput;
        const material = updateMaterialMetadata(storeState, materialId, body);
        persistFn(storeState);
        res.status(200).json({
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 3B. DELETE /api/materials/:id — Delete unused material (blocks if material has history)
  app.delete(
    '/api/materials/:id',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const materialId = String(req.params.id ?? '');
        const deletedMaterialId = deleteMaterial(storeState, materialId);
        persistFn(storeState);
        res.status(200).json({
          deletedMaterialId,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 3C. POST /api/materials/:id/archive — Archive or restore a material with transaction history
  app.post(
    '/api/materials/:id/archive',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const materialId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as ArchiveMaterialInput;
        const isArchived =
          typeof body.isArchived === 'boolean' ? body.isArchived : true;
        const material = setMaterialArchivedStatus(
          storeState,
          materialId,
          isArchived,
          req.authUser?.username || 'admin'
        );
        persistFn(storeState);
        res.status(200).json({
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 3D. POST /api/categories & DELETE /api/categories/:id
  app.post(
    '/api/categories',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateCategoryInput;
        const category = createCategory(storeState, body);
        persistFn(storeState);
        res.status(201).json({
          category,
          categories: storeState.categories,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.delete(
    '/api/categories/:id',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const categoryId = String(req.params.id ?? '');
        const deletedCategoryId = deleteCategory(storeState, categoryId);
        persistFn(storeState);
        res.status(200).json({
          deletedCategoryId,
          categories: storeState.categories,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 4. POST /api/sales (FR-006..FR-012, BR-002, BR-003, FAIL-004)
  app.post(
    '/api/sales',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateSaleInput;
        const sale = recordMultiItemSale(
          storeState,
          body,
          new Date().toISOString(),
          req.authUser?.username
        );
        persistFn(storeState);
        res.status(201).json({
          sale,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 4B. POST /api/sales/:id/reverse & block permanent DELETE /api/sales/:id
  app.post(
    '/api/sales/:id/reverse',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const saleId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as ReverseTransactionInput;
        const sale = reverseSaleTransaction(
          storeState,
          saleId,
          body.reason,
          req.authUser?.username || 'admin'
        );
        persistFn(storeState);
        res.status(200).json({
          sale,
          sales: storeState.sales,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.delete(
    '/api/sales/:id',
    requireAuth,
    (_req: Request, _res: Response, next: NextFunction) => {
      next(
        new AppDomainError(
          'DELETION_PROHIBITED',
          'Completed sales transactions cannot be permanently deleted. Use the sale reversal workflow so inventory and audit history remain intact.'
        )
      );
    }
  );

  // 5. POST /api/stock-in (FR-013..FR-015, BR-004, BR-006, BR-007)
  app.post(
    '/api/stock-in',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateStockInInput;
        const { stockIn, material } = recordStockIn(
          storeState,
          body,
          new Date().toISOString(),
          req.authUser?.username
        );
        persistFn(storeState);
        res.status(201).json({
          stockIn,
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 5B. POST /api/stock-in/:id/reverse & block permanent DELETE /api/stock-in/:id
  app.post(
    '/api/stock-in/:id/reverse',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const stockInId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as ReverseTransactionInput;
        const { stockIn, material } = reverseStockInRecord(
          storeState,
          stockInId,
          body.reason,
          req.authUser?.username || 'admin'
        );
        persistFn(storeState);
        res.status(200).json({
          stockIn,
          stockIns: storeState.stockIns,
          material,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.delete(
    '/api/stock-in/:id',
    requireAuth,
    (_req: Request, _res: Response, next: NextFunction) => {
      next(
        new AppDomainError(
          'DELETION_PROHIBITED',
          'Completed Stock-In transactions cannot be permanently deleted. Use the authorized Stock-In reversal workflow.'
        )
      );
    }
  );

  // 6. POST /api/audits (FR-016..FR-019, BR-004, BR-008, VAL-003, VAL-006, VAL-007)
  app.post(
    '/api/audits',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const body = (req.body ?? {}) as CreateAuditInput;
        const audit = recordStockAudit(
          storeState,
          body,
          new Date().toISOString(),
          req.authUser?.username
        );
        persistFn(storeState);
        res.status(201).json({
          audit,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  // 6B. POST /api/audits/:id/reverse & block permanent DELETE /api/audits/:id
  app.post(
    '/api/audits/:id/reverse',
    requireAuth,
    (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
      try {
        const auditId = String(req.params.id ?? '');
        const body = (req.body ?? {}) as ReverseTransactionInput;
        const audit = reverseStockAuditRecord(
          storeState,
          auditId,
          body.reason,
          req.authUser?.username || 'admin'
        );
        persistFn(storeState);
        res.status(200).json({
          audit,
          audits: storeState.audits,
          materials: storeState.materials,
          summary: storeState.summary,
        });
      } catch (err) {
        next(err);
      }
    }
  );

  app.delete(
    '/api/audits/:id',
    requireAuth,
    (_req: Request, _res: Response, next: NextFunction) => {
      next(
        new AppDomainError(
          'DELETION_PROHIBITED',
          'Completed ground-stock audits cannot be permanently deleted. Use the audit reversal procedure.'
        )
      );
    }
  );

  // Centralized Domain & API Error Boundary (SEC-001, docs/API_CONTRACT.md Section 3.2)
  app.use(
    (err: unknown, _req: Request, res: Response, _next: NextFunction) => {
      if (err instanceof AppDomainError) {
        res.status(err.statusHttp).json(err.toEnvelope());
        return;
      }
      const fallback = new AppDomainError(
        'INTERNAL_ERROR',
        err instanceof Error ? err.message : 'Unexpected server error'
      );
      res.status(500).json(fallback.toEnvelope());
    }
  );

  return {
    app,
    getState: () => storeState,
    sessions,
  };
}

async function startServer() {
  const { app } = createErpApiApp();

  // Mount Vite dev middleware in development or static dist in production
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.resolve(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (_req: Request, res: Response) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(
      `Construction & Finishing ERP Server listening on http://0.0.0.0:${PORT}`
    );
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  startServer();
}
