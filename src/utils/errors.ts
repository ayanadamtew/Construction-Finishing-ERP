import { ApiErrorDetails, ApiErrorEnvelope, ErrorCode } from '../types/erp';

function defaultHttpStatusForCode(code: ErrorCode): number {
  switch (code) {
    case 'UNAUTHORIZED':
    case 'INVALID_CREDENTIALS':
      return 401;
    case 'FORBIDDEN':
    case 'ACCOUNT_DEACTIVATED':
      return 403;
    case 'MATERIAL_NOT_FOUND':
    case 'RECORD_NOT_FOUND':
      return 404;
    case 'MATERIAL_HAS_HISTORY':
    case 'MATERIAL_ARCHIVED':
    case 'CATEGORY_IN_USE':
    case 'ALREADY_REVERSED':
    case 'INSUFFICIENT_STOCK_FOR_REVERSAL':
    case 'LAST_ADMIN_PROTECTION':
    case 'DELETION_PROHIBITED':
    case 'DUPLICATE_RECORD':
      return 409;
    case 'INTERNAL_ERROR':
      return 500;
    default:
      return 400;
  }
}

/**
 * Structured Domain & API Error class
 * Enforces deterministic HTTP status codes and machine-readable error envelopes
 * per docs/ARCHITECTURE.md Section 12 and docs/API_CONTRACT.md Section 3.2.
 */
export class AppDomainError extends Error {
  public readonly code: ErrorCode;
  public readonly statusHttp: number;
  public readonly details?: ApiErrorDetails;

  constructor(
    code: ErrorCode,
    message: string,
    details?: ApiErrorDetails,
    statusHttp?: number
  ) {
    super(message);
    this.name = 'AppDomainError';
    this.code = code;
    this.details = details;
    this.statusHttp = statusHttp ?? defaultHttpStatusForCode(code);
  }

  public toEnvelope(): ApiErrorEnvelope {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(this.details ? { details: this.details } : {}),
      },
    };
  }
}

export function isApiErrorEnvelope(value: unknown): value is ApiErrorEnvelope {
  if (!value || typeof value !== 'object') return false;
  const candidate = value as Record<string, unknown>;
  if (!candidate.error || typeof candidate.error !== 'object') return false;
  const err = candidate.error as Record<string, unknown>;
  return typeof err.code === 'string' && typeof err.message === 'string';
}
