/**
 * Shared Domain & API Types
 * Source of Truth: docs/SRS.md, docs/DATABASE_DESIGN.md, docs/API_CONTRACT.md
 */

export type LanguageCode = 'en' | 'am' | 'om';

export type AppRouteTab = 'dashboard' | 'materials' | 'pos' | 'stock-in' | 'audit-log';

export enum MaterialCategory {
  REBAR = 'rebar',
  CEMENT = 'cement',
  TILES = 'tiles',
  PAINT = 'paint',
  HARDWARE = 'hardware',
  OTHER = 'other',
}

export enum MaterialUnit {
  PCS = 'pcs',
  BARS = 'bars',
  BAGS = 'bags',
  BOXES = 'boxes',
  BUCKETS = 'buckets',
  KG = 'kg',
  M = 'm',
  LITERS = 'liters',
}

export const ALLOWED_CATEGORIES: readonly MaterialCategory[] = [
  MaterialCategory.REBAR,
  MaterialCategory.CEMENT,
  MaterialCategory.TILES,
  MaterialCategory.PAINT,
  MaterialCategory.HARDWARE,
  MaterialCategory.OTHER,
];

export const ALLOWED_UNITS: readonly MaterialUnit[] = [
  MaterialUnit.PCS,
  MaterialUnit.BARS,
  MaterialUnit.BAGS,
  MaterialUnit.BOXES,
  MaterialUnit.BUCKETS,
  MaterialUnit.KG,
  MaterialUnit.M,
  MaterialUnit.LITERS,
];

export interface CategoryItem {
  id: string;
  name: string;
  isSystemDefault?: boolean;
  createdAt: string;
}

export interface CreateCategoryInput {
  id?: string;
  name: string;
}

export interface CategoryMutationResponse {
  category?: CategoryItem;
  deletedCategoryId?: string;
  categories: CategoryItem[];
}

export type UserRole = 'admin' | 'staff';

export interface UserAccount {
  id: string;
  username: string;
  displayName: string;
  role: UserRole;
  passwordHash: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface PublicUser {
  id: string;
  username: string;
  displayName: string;
  role: UserRole;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface LoginInput {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: PublicUser;
}

export interface CreateUserInput {
  username: string;
  displayName?: string;
  password: string;
  role?: UserRole;
}

export interface UpdateUserStatusInput {
  isActive: boolean;
}

export interface Material {
  id: string;
  name: string;
  category: MaterialCategory | string;
  specs: string;
  unit: MaterialUnit;
  currentStock: number;
  minStockLevel: number;
  unitCost: number;
  defaultSellingPrice: number;
  isArchived?: boolean;
  archivedAt?: string;
  archivedBy?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateMaterialInput {
  name: string;
  category: MaterialCategory | string;
  specs?: string;
  unit: MaterialUnit | string;
  initialStock: number;
  minStockLevel: number;
  unitCost: number;
  defaultSellingPrice: number;
}

export interface UpdateMaterialInput {
  name?: string;
  category?: MaterialCategory | string;
  specs?: string;
  unit?: MaterialUnit | string;
  minStockLevel?: number;
  defaultSellingPrice?: number;
  currentStock?: unknown;
  initialStock?: unknown;
}

export interface MaterialMutationResponse {
  material: Material;
  materials: Material[];
  summary: StoreSummary;
}

export interface DeleteMaterialResponse {
  deletedMaterialId: string;
  materials: Material[];
  summary: StoreSummary;
}

export interface ArchiveMaterialInput {
  isArchived: boolean;
}

export interface SaleLineInput {
  materialId: string;
  quantity: number;
  unitSellingPrice: number;
}

export interface CreateSaleInput {
  customerNote?: string;
  items: SaleLineInput[];
}

export interface SaleLineItem {
  materialId: string;
  materialName: string;
  unit: MaterialUnit;
  quantity: number;
  unitSellingPrice: number;
  unitCostSnapshot: number;
  lineTotal: number;
  lineProfit: number;
}

export interface SaleTransaction {
  id: string;
  createdAt: string;
  customerNote: string;
  items: SaleLineItem[];
  totalRevenue: number;
  totalProfit: number;
  createdBy?: string;
  isReversed?: boolean;
  reversedAt?: string;
  reversedBy?: string;
  reversalReason?: string;
}

export interface CreateSaleResponse {
  sale: SaleTransaction;
  materials: Material[];
  summary: StoreSummary;
}

export interface ReverseTransactionInput {
  reason: string;
}

export interface ReverseSaleResponse {
  sale: SaleTransaction;
  sales: SaleTransaction[];
  materials: Material[];
  summary: StoreSummary;
}

export interface DraftPosCartItem {
  materialId: string;
  quantityInput: string;
  unitPriceInput: string;
}

export interface CreateStockInInput {
  materialId: string;
  quantityAdded: number;
  unitPurchaseCost: number;
  supplierNote?: string;
}

export interface StockInRecord {
  id: string;
  materialId: string;
  materialName: string;
  unit: MaterialUnit;
  quantityAdded: number;
  unitPurchaseCost: number;
  totalCost: number;
  previousStock: number;
  newStock: number;
  previousUnitCost?: number;
  supplierNote: string;
  createdAt: string;
  createdBy?: string;
  isReversed?: boolean;
  reversedAt?: string;
  reversedBy?: string;
  reversalReason?: string;
}

export interface CreateStockInResponse {
  stockIn: StockInRecord;
  material: Material;
  materials: Material[];
  summary: StoreSummary;
}

export interface ReverseStockInResponse {
  stockIn: StockInRecord;
  stockIns: StockInRecord[];
  material: Material;
  materials: Material[];
  summary: StoreSummary;
}

export interface AuditItemInput {
  materialId: string;
  physicalCount: number;
}

export interface CreateAuditInput {
  note?: string;
  items: AuditItemInput[];
}

export interface AuditLineItem {
  materialId: string;
  materialName: string;
  unit: MaterialUnit;
  expectedStock: number;
  physicalCount: number;
  variance: number;
  unitCostSnapshot: number;
}

export interface StockAuditRecord {
  id: string;
  createdAt: string;
  note: string;
  adjustments: AuditLineItem[];
  createdBy?: string;
  isReversed?: boolean;
  reversedAt?: string;
  reversedBy?: string;
  reversalReason?: string;
}

export interface CreateAuditResponse {
  audit: StockAuditRecord;
  materials: Material[];
  summary: StoreSummary;
}

export interface ReverseAuditResponse {
  audit: StockAuditRecord;
  audits: StockAuditRecord[];
  materials: Material[];
  summary: StoreSummary;
}

export interface StoreSummary {
  totalRevenue: number;
  totalProfit: number;
  inventoryCostValue: number;
  inventoryRetailValue: number;
  lowStockCount: number;
}

export interface ErpState {
  materials: Material[];
  categories?: CategoryItem[];
  sales: SaleTransaction[];
  stockIns: StockInRecord[];
  audits: StockAuditRecord[];
  users?: UserAccount[];
  summary: StoreSummary;
}

export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'INSUFFICIENT_STOCK'
  | 'IMMUTABLE_FIELD_VIOLATION'
  | 'MATERIAL_NOT_FOUND'
  | 'RECORD_NOT_FOUND'
  | 'UNAUTHORIZED'
  | 'INVALID_CREDENTIALS'
  | 'ACCOUNT_DEACTIVATED'
  | 'FORBIDDEN'
  | 'MATERIAL_HAS_HISTORY'
  | 'MATERIAL_ARCHIVED'
  | 'CATEGORY_IN_USE'
  | 'ALREADY_REVERSED'
  | 'INSUFFICIENT_STOCK_FOR_REVERSAL'
  | 'LAST_ADMIN_PROTECTION'
  | 'DELETION_PROHIBITED'
  | 'DUPLICATE_RECORD'
  | 'INTERNAL_ERROR';

export interface ApiErrorDetails {
  materialId?: string;
  materialName?: string;
  categoryId?: string;
  recordId?: string;
  requested?: number;
  available?: number;
  inUseCount?: number;
  unit?: string;
  field?: string;
}

export interface ApiErrorEnvelope {
  error: {
    code: ErrorCode;
    message: string;
    details?: ApiErrorDetails;
  };
}
