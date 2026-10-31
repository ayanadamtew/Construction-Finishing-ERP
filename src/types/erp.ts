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

export interface Material {
  id: string;
  name: string;
  category: MaterialCategory;
  specs: string;
  unit: MaterialUnit;
  currentStock: number;
  minStockLevel: number;
  unitCost: number;
  defaultSellingPrice: number;
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
}

export interface CreateSaleResponse {
  sale: SaleTransaction;
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
  supplierNote: string;
  createdAt: string;
}

export interface CreateStockInResponse {
  stockIn: StockInRecord;
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
}

export interface CreateAuditResponse {
  audit: StockAuditRecord;
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
  sales: SaleTransaction[];
  stockIns: StockInRecord[];
  audits: StockAuditRecord[];
  summary: StoreSummary;
}

export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'INSUFFICIENT_STOCK'
  | 'IMMUTABLE_FIELD_VIOLATION'
  | 'MATERIAL_NOT_FOUND'
  | 'INTERNAL_ERROR';

export interface ApiErrorDetails {
  materialId?: string;
  materialName?: string;
  requested?: number;
  available?: number;
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
