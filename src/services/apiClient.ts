import {
  CategoryMutationResponse,
  CreateAuditInput,
  CreateAuditResponse,
  CreateCategoryInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateSaleResponse,
  CreateStockInInput,
  CreateStockInResponse,
  CreateUserInput,
  DeleteMaterialResponse,
  ErpState,
  LoginInput,
  LoginResponse,
  MaterialMutationResponse,
  PublicUser,
  ReverseAuditResponse,
  ReverseSaleResponse,
  ReverseStockInResponse,
  UpdateMaterialInput,
} from '../types/erp';
import { AppDomainError, isApiErrorEnvelope } from '../utils/errors';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';
const AUTH_TOKEN_STORAGE_KEY = 'erp_auth_session_token';

export function getStoredAuthToken(): string | null {
  try {
    return window.localStorage.getItem(AUTH_TOKEN_STORAGE_KEY);
  } catch {
    return null;
  }
}

export function setStoredAuthToken(token: string | null): void {
  try {
    if (token) {
      window.localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, token);
    } else {
      window.localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY);
    }
  } catch {
    // Ignore storage errors in restricted environments
  }
}

async function requestJson<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const token = getStoredAuthToken();
  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options?.headers || {}),
      },
    });
  } catch {
    throw new AppDomainError(
      'INTERNAL_ERROR',
      'Network error while connecting to store server.'
    );
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    throw new AppDomainError(
      'INTERNAL_ERROR',
      `Invalid response from server (HTTP ${response.status}).`
    );
  }

  if (!response.ok) {
    if (isApiErrorEnvelope(payload)) {
      throw new AppDomainError(
        payload.error.code,
        payload.error.message,
        payload.error.details,
        response.status
      );
    }
    throw new AppDomainError(
      'INTERNAL_ERROR',
      `Request failed with status ${response.status}.`
    );
  }

  return payload as T;
}

export const erpApiClient = {
  /**
   * POST /api/auth/login — Authenticates pre-registered credentials and stores session token.
   */
  async login(payload: LoginInput): Promise<LoginResponse> {
    const res = await requestJson<LoginResponse>('/auth/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    setStoredAuthToken(res.token);
    return res;
  },

  /**
   * POST /api/auth/logout — Invalidates current session token.
   */
  async logout(): Promise<void> {
    try {
      await requestJson<{ success: boolean }>('/auth/logout', {
        method: 'POST',
      });
    } finally {
      setStoredAuthToken(null);
    }
  },

  /**
   * GET /api/auth/me — Verifies persisted session token and returns current user.
   */
  fetchCurrentUser(): Promise<{ user: PublicUser }> {
    return requestJson<{ user: PublicUser }>('/auth/me', { method: 'GET' });
  },

  /**
   * GET /api/users — Lists all authorized user accounts (Admin only).
   */
  fetchUsers(): Promise<{ users: PublicUser[] }> {
    return requestJson<{ users: PublicUser[] }>('/users', { method: 'GET' });
  },

  /**
   * POST /api/users — Creates a pre-registered user account (Admin only).
   */
  createUser(
    payload: CreateUserInput
  ): Promise<{ user: PublicUser; users: PublicUser[] }> {
    return requestJson<{ user: PublicUser; users: PublicUser[] }>('/users', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * PATCH /api/users/:id/status — Activates or deactivates a user account (Admin only).
   */
  updateUserStatus(
    userId: string,
    isActive: boolean
  ): Promise<{ user: PublicUser; users: PublicUser[] }> {
    return requestJson<{ user: PublicUser; users: PublicUser[] }>(
      `/users/${encodeURIComponent(userId)}/status`,
      {
        method: 'PATCH',
        body: JSON.stringify({ isActive }),
      }
    );
  },

  /**
   * DELETE /api/users/:id — Deletes a user account (Admin only, protects last admin).
   */
  deleteUser(
    userId: string
  ): Promise<{ deletedUserId: string; users: PublicUser[] }> {
    return requestJson<{ deletedUserId: string; users: PublicUser[] }>(
      `/users/${encodeURIComponent(userId)}`,
      {
        method: 'DELETE',
      }
    );
  },

  /**
   * GET /api/state — Retrieves canonical store catalog, transactions, and summary KPIs.
   */
  fetchStoreState(): Promise<ErpState> {
    return requestJson<ErpState>('/state', { method: 'GET' });
  },

  /**
   * POST /api/materials — Registers a new SKU-free construction or finishing material.
   */
  createMaterial(
    payload: CreateMaterialInput
  ): Promise<MaterialMutationResponse> {
    return requestJson<MaterialMutationResponse>('/materials', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * PATCH /api/materials/:id — Updates mutable material metadata.
   */
  updateMaterial(
    materialId: string,
    payload: UpdateMaterialInput
  ): Promise<MaterialMutationResponse> {
    return requestJson<MaterialMutationResponse>(
      `/materials/${encodeURIComponent(materialId)}`,
      {
        method: 'PATCH',
        body: JSON.stringify(payload),
      }
    );
  },

  /**
   * DELETE /api/materials/:id — Permanently deletes an unused material.
   */
  deleteMaterial(materialId: string): Promise<DeleteMaterialResponse> {
    return requestJson<DeleteMaterialResponse>(
      `/materials/${encodeURIComponent(materialId)}`,
      {
        method: 'DELETE',
      }
    );
  },

  /**
   * POST /api/materials/:id/archive — Archives or restores a material with history.
   */
  setMaterialArchived(
    materialId: string,
    isArchived: boolean
  ): Promise<MaterialMutationResponse> {
    return requestJson<MaterialMutationResponse>(
      `/materials/${encodeURIComponent(materialId)}/archive`,
      {
        method: 'POST',
        body: JSON.stringify({ isArchived }),
      }
    );
  },

  /**
   * POST /api/categories — Creates a new material category.
   */
  createCategory(
    payload: CreateCategoryInput
  ): Promise<CategoryMutationResponse> {
    return requestJson<CategoryMutationResponse>('/categories', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * DELETE /api/categories/:id — Deletes an unused category.
   */
  deleteCategory(categoryId: string): Promise<CategoryMutationResponse> {
    return requestJson<CategoryMutationResponse>(
      `/categories/${encodeURIComponent(categoryId)}`,
      {
        method: 'DELETE',
      }
    );
  },

  /**
   * POST /api/sales — Records an atomic multi-item sale and deducts inventory.
   */
  createSale(payload: CreateSaleInput): Promise<CreateSaleResponse> {
    return requestJson<CreateSaleResponse>('/sales', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * POST /api/sales/:id/reverse — Reverses a completed sale and restores inventory.
   */
  reverseSale(saleId: string, reason: string): Promise<ReverseSaleResponse> {
    return requestJson<ReverseSaleResponse>(
      `/sales/${encodeURIComponent(saleId)}/reverse`,
      {
        method: 'POST',
        body: JSON.stringify({ reason }),
      }
    );
  },

  /**
   * POST /api/stock-in — Records supplier restocking and updates weighted-average unit cost.
   */
  createStockIn(payload: CreateStockInInput): Promise<CreateStockInResponse> {
    return requestJson<CreateStockInResponse>('/stock-in', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * POST /api/stock-in/:id/reverse — Reverses a Stock-In delivery and corrects stock/cost.
   */
  reverseStockIn(
    stockInId: string,
    reason: string
  ): Promise<ReverseStockInResponse> {
    return requestJson<ReverseStockInResponse>(
      `/stock-in/${encodeURIComponent(stockInId)}/reverse`,
      {
        method: 'POST',
        body: JSON.stringify({ reason }),
      }
    );
  },

  /**
   * POST /api/audits — Commits a physical ground-stock audit reconciliation.
   */
  createAudit(payload: CreateAuditInput): Promise<CreateAuditResponse> {
    return requestJson<CreateAuditResponse>('/audits', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  /**
   * POST /api/audits/:id/reverse — Reverses a physical ground-stock audit adjustment.
   */
  reverseAudit(auditId: string, reason: string): Promise<ReverseAuditResponse> {
    return requestJson<ReverseAuditResponse>(
      `/audits/${encodeURIComponent(auditId)}/reverse`,
      {
        method: 'POST',
        body: JSON.stringify({ reason }),
      }
    );
  },
};
