import {
  CreateAuditInput,
  CreateAuditResponse,
  CreateMaterialInput,
  CreateSaleInput,
  CreateSaleResponse,
  CreateStockInInput,
  CreateStockInResponse,
  ErpState,
  MaterialMutationResponse,
  UpdateMaterialInput,
} from '../types/erp';
import { AppDomainError, isApiErrorEnvelope } from '../utils/errors';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

async function requestJson<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...(options?.headers || {}),
      },
      ...options,
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
   * POST /api/sales — Records an atomic multi-item sale and deducts inventory.
   */
  createSale(payload: CreateSaleInput): Promise<CreateSaleResponse> {
    return requestJson<CreateSaleResponse>('/sales', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
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
   * POST /api/audits — Commits a physical ground-stock audit reconciliation.
   */
  createAudit(payload: CreateAuditInput): Promise<CreateAuditResponse> {
    return requestJson<CreateAuditResponse>('/audits', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
};
