import {
  ALLOWED_CATEGORIES,
  ALLOWED_UNITS,
  AuditLineItem,
  CreateAuditInput,
  CreateMaterialInput,
  CreateSaleInput,
  CreateStockInInput,
  ErpState,
  Material,
  MaterialCategory,
  MaterialUnit,
  SaleLineItem,
  SaleTransaction,
  StockAuditRecord,
  StockInRecord,
  StoreSummary,
  UpdateMaterialInput,
} from '../types/erp';
import { AppDomainError } from '../utils/errors';

/**
 * Rounds any numeric value deterministically to 2 decimal places (NFR-003).
 */
export function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

/**
 * Validates that a numeric value is finite and >= 0 (VAL-003).
 */
export function assertNonNegativeNumber(
  value: unknown,
  fieldName: string
): number {
  const num = typeof value === 'number' ? value : Number(value);
  if (
    value === '' ||
    value === null ||
    value === undefined ||
    typeof value === 'boolean' ||
    !Number.isFinite(num) ||
    num < 0
  ) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `${fieldName} must be a non-negative number.`,
      { field: fieldName }
    );
  }
  return round2(num);
}

/**
 * Validates that a numeric value is finite and strictly > 0 (VAL-004).
 */
export function assertPositiveNumber(
  value: unknown,
  fieldName: string
): number {
  const num = typeof value === 'number' ? value : Number(value);
  if (
    value === '' ||
    value === null ||
    value === undefined ||
    typeof value === 'boolean' ||
    !Number.isFinite(num) ||
    num <= 0
  ) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `${fieldName} must be a positive number greater than 0.`,
      { field: fieldName }
    );
  }
  return round2(num);
}

/**
 * Validates and sanitizes material name (VAL-001: 1..120 chars after trim).
 */
export function validateMaterialName(name: unknown): string {
  if (typeof name !== 'string') {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Material name is required.',
      { field: 'name' }
    );
  }
  const trimmed = name.trim();
  if (trimmed.length < 1 || trimmed.length > 120) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Material name must be between 1 and 120 characters.',
      { field: 'name' }
    );
  }
  return trimmed;
}

/**
 * Validates optional material specifications string (0..120 chars).
 */
export function validateMaterialSpecs(specs: unknown): string {
  if (specs === undefined || specs === null) return '';
  if (typeof specs !== 'string') {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Material specifications must be text.',
      { field: 'specs' }
    );
  }
  const trimmed = specs.trim();
  if (trimmed.length > 120) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Material specifications must not exceed 120 characters.',
      { field: 'specs' }
    );
  }
  return trimmed;
}

/**
 * Validates optional note fields (customerNote, supplierNote, audit note).
 */
export function validateOptionalNote(
  note: unknown,
  fieldName: string,
  maxLength: number = 200
): string {
  if (note === undefined || note === null) return '';
  if (typeof note !== 'string') {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `${fieldName} must be text.`,
      { field: fieldName }
    );
  }
  const trimmed = note.trim();
  if (trimmed.length > maxLength) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `${fieldName} must not exceed ${maxLength} characters.`,
      { field: fieldName }
    );
  }
  return trimmed;
}

/**
 * Computes the derived StoreSummary KPIs from canonical state (FR-020).
 */
export function calculateStoreSummary(
  materials: Material[],
  sales: SaleTransaction[]
): StoreSummary {
  const totalRevenue = round2(
    sales.reduce((sum, sale) => sum + sale.totalRevenue, 0)
  );
  const totalProfit = round2(
    sales.reduce((sum, sale) => sum + sale.totalProfit, 0)
  );
  const inventoryCostValue = round2(
    materials.reduce(
      (sum, mat) => sum + round2(mat.currentStock * mat.unitCost),
      0
    )
  );
  const inventoryRetailValue = round2(
    materials.reduce(
      (sum, mat) => sum + round2(mat.currentStock * mat.defaultSellingPrice),
      0
    )
  );
  const lowStockCount = materials.filter(
    (mat) => mat.currentStock <= mat.minStockLevel
  ).length;

  return {
    totalRevenue,
    totalProfit,
    inventoryCostValue,
    inventoryRetailValue,
    lowStockCount,
  };
}

/**
 * Validates that a material category and tracking unit belong to allowed enums (VAL-002).
 */
export function validateCategoryAndUnit(
  category: string,
  unit: string
): { category: MaterialCategory; unit: MaterialUnit } {
  if (!ALLOWED_CATEGORIES.includes(category as MaterialCategory)) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `Invalid material category: ${category}`,
      { field: 'category' }
    );
  }
  if (!ALLOWED_UNITS.includes(unit as MaterialUnit)) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      `Invalid material tracking unit: ${unit}`,
      { field: 'unit' }
    );
  }
  return {
    category: category as MaterialCategory,
    unit: unit as MaterialUnit,
  };
}

/**
 * Checks whether a material already has any recorded transactions in the ledger (BR-001).
 */
export function materialHasTransactions(
  state: Pick<ErpState, 'sales' | 'stockIns' | 'audits'>,
  materialId: string
): boolean {
  const inSales = state.sales.some((sale) =>
    sale.items.some((item) => item.materialId === materialId)
  );
  if (inSales) return true;

  const inStockIns = state.stockIns.some(
    (rec) => rec.materialId === materialId
  );
  if (inStockIns) return true;

  const inAudits = state.audits.some((audit) =>
    audit.adjustments.some((adj) => adj.materialId === materialId)
  );
  return inAudits;
}

/**
 * Registers a new SKU-free construction or finishing material (FR-001, FR-002, BR-005).
 */
export function registerMaterial(
  state: ErpState,
  input: CreateMaterialInput,
  nowIso: string = new Date().toISOString()
): Material {
  const name = validateMaterialName(input.name);
  const specs = validateMaterialSpecs(input.specs);
  const { category, unit } = validateCategoryAndUnit(
    String(input.category ?? ''),
    String(input.unit ?? '')
  );
  const currentStock = assertNonNegativeNumber(
    input.initialStock,
    'initialStock'
  );
  const minStockLevel = assertNonNegativeNumber(
    input.minStockLevel,
    'minStockLevel'
  );
  const unitCost = assertNonNegativeNumber(input.unitCost, 'unitCost');
  const defaultSellingPrice = assertNonNegativeNumber(
    input.defaultSellingPrice,
    'defaultSellingPrice'
  );

  const newMaterial: Material = {
    id: `mat_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    name,
    category,
    specs,
    unit,
    currentStock,
    minStockLevel,
    unitCost,
    defaultSellingPrice,
    createdAt: nowIso,
    updatedAt: nowIso,
  };

  state.materials.unshift(newMaterial);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return newMaterial;
}

/**
 * Updates mutable metadata of an existing material while strictly blocking
 * direct currentStock mutation (FR-003, FR-004, BR-001, BR-004).
 */
export function updateMaterialMetadata(
  state: ErpState,
  materialId: string,
  input: UpdateMaterialInput,
  nowIso: string = new Date().toISOString()
): Material {
  const material = state.materials.find((m) => m.id === materialId);
  if (!material) {
    throw new AppDomainError(
      'MATERIAL_NOT_FOUND',
      `Material with ID "${materialId}" was not found.`,
      { materialId }
    );
  }

  if (input.currentStock !== undefined || input.initialStock !== undefined) {
    throw new AppDomainError(
      'IMMUTABLE_FIELD_VIOLATION',
      'Direct editing of currentStock is forbidden. Stock changes must occur via Sale, Stock-In, or Ground-Stock Audit.',
      { materialId, field: 'currentStock' }
    );
  }

  const nextName =
    input.name !== undefined ? validateMaterialName(input.name) : material.name;
  const nextSpecs =
    input.specs !== undefined
      ? validateMaterialSpecs(input.specs)
      : material.specs;
  const nextCategoryStr =
    input.category !== undefined ? String(input.category) : material.category;
  const nextUnitStr =
    input.unit !== undefined ? String(input.unit) : material.unit;

  const { category: nextCategory, unit: nextUnit } = validateCategoryAndUnit(
    nextCategoryStr,
    nextUnitStr
  );

  if (
    nextUnit !== material.unit &&
    materialHasTransactions(state, materialId)
  ) {
    throw new AppDomainError(
      'IMMUTABLE_FIELD_VIOLATION',
      'Tracking unit cannot be changed after transactions have been recorded for this material.',
      { materialId, field: 'unit', unit: material.unit }
    );
  }

  const nextMinStockLevel =
    input.minStockLevel !== undefined
      ? assertNonNegativeNumber(input.minStockLevel, 'minStockLevel')
      : material.minStockLevel;

  const nextDefaultSellingPrice =
    input.defaultSellingPrice !== undefined
      ? assertNonNegativeNumber(
          input.defaultSellingPrice,
          'defaultSellingPrice'
        )
      : material.defaultSellingPrice;

  material.name = nextName;
  material.specs = nextSpecs;
  material.category = nextCategory;
  material.unit = nextUnit;
  material.minStockLevel = nextMinStockLevel;
  material.defaultSellingPrice = nextDefaultSellingPrice;
  material.updatedAt = nowIso;

  state.summary = calculateStoreSummary(state.materials, state.sales);
  return material;
}

/**
 * Executes an atomic multi-item sale transaction with strict stock-floor blocking
 * and aggregate duplicate-line protection (FR-006..FR-012, BR-002, BR-003, FAIL-004).
 */
export function recordMultiItemSale(
  state: ErpState,
  input: CreateSaleInput,
  nowIso: string = new Date().toISOString()
): SaleTransaction {
  if (!input || !Array.isArray(input.items) || input.items.length === 0) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'A sale transaction must include at least one material line item.',
      { field: 'items' }
    );
  }

  const customerNote = validateOptionalNote(
    input.customerNote,
    'customerNote',
    200
  );

  const aggregatedMap = new Map<
    string,
    { materialId: string; quantity: number; unitSellingPrice: number }
  >();

  for (const rawItem of input.items) {
    if (
      !rawItem ||
      typeof rawItem.materialId !== 'string' ||
      !rawItem.materialId.trim()
    ) {
      throw new AppDomainError(
        'VALIDATION_ERROR',
        'Each sale line item must specify a valid materialId.',
        { field: 'materialId' }
      );
    }
    const materialId = rawItem.materialId.trim();
    const quantity = assertPositiveNumber(rawItem.quantity, 'quantity');
    const unitSellingPrice = assertNonNegativeNumber(
      rawItem.unitSellingPrice,
      'unitSellingPrice'
    );

    const existing = aggregatedMap.get(materialId);
    if (existing) {
      existing.quantity = round2(existing.quantity + quantity);
      existing.unitSellingPrice = unitSellingPrice;
    } else {
      aggregatedMap.set(materialId, {
        materialId,
        quantity,
        unitSellingPrice,
      });
    }
  }

  const validatedPlans: Array<{
    material: Material;
    lineItem: SaleLineItem;
  }> = [];

  for (const entry of aggregatedMap.values()) {
    const material = state.materials.find((m) => m.id === entry.materialId);
    if (!material) {
      throw new AppDomainError(
        'MATERIAL_NOT_FOUND',
        `Material with ID "${entry.materialId}" was not found.`,
        { materialId: entry.materialId }
      );
    }

    if (entry.quantity > material.currentStock) {
      throw new AppDomainError(
        'INSUFFICIENT_STOCK',
        `Requested quantity (${entry.quantity}) for ${material.name} exceeds available stock (${material.currentStock}).`,
        {
          materialId: material.id,
          materialName: material.name,
          requested: entry.quantity,
          available: material.currentStock,
          unit: material.unit,
        }
      );
    }

    const lineTotal = round2(entry.quantity * entry.unitSellingPrice);
    const lineProfit = round2(
      entry.quantity * (entry.unitSellingPrice - material.unitCost)
    );

    validatedPlans.push({
      material,
      lineItem: {
        materialId: material.id,
        materialName: material.name,
        unit: material.unit,
        quantity: entry.quantity,
        unitSellingPrice: entry.unitSellingPrice,
        unitCostSnapshot: material.unitCost,
        lineTotal,
        lineProfit,
      },
    });
  }

  const saleLineItems: SaleLineItem[] = [];
  for (const plan of validatedPlans) {
    plan.material.currentStock = round2(
      plan.material.currentStock - plan.lineItem.quantity
    );
    plan.material.updatedAt = nowIso;
    saleLineItems.push(plan.lineItem);
  }

  const totalRevenue = round2(
    saleLineItems.reduce((sum, item) => sum + item.lineTotal, 0)
  );
  const totalProfit = round2(
    saleLineItems.reduce((sum, item) => sum + item.lineProfit, 0)
  );

  const saleTransaction: SaleTransaction = {
    id: `sale_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    createdAt: nowIso,
    customerNote,
    items: saleLineItems,
    totalRevenue,
    totalProfit,
  };

  state.sales.unshift(saleTransaction);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return saleTransaction;
}

/**
 * Computes the updated weighted-average supplier unit cost (BR-006).
 * If previousStock == 0, returns unitPurchaseCost directly.
 */
export function calculateWeightedAverageCost(
  previousStock: number,
  oldUnitCost: number,
  quantityAdded: number,
  unitPurchaseCost: number
): number {
  if (previousStock <= 0) {
    return round2(unitPurchaseCost);
  }
  const totalStock = previousStock + quantityAdded;
  if (totalStock <= 0) {
    return round2(unitPurchaseCost);
  }
  const weightedSum =
    previousStock * oldUnitCost + quantityAdded * unitPurchaseCost;
  return round2(weightedSum / totalStock);
}

/**
 * Records a Stock-In (supplier restocking) transaction with supplier unit purchase cost
 * and updates the material's stock and weighted-average unit cost (FR-013..FR-015, BR-006).
 */
export function recordStockIn(
  state: ErpState,
  input: CreateStockInInput,
  nowIso: string = new Date().toISOString()
): { stockIn: StockInRecord; material: Material } {
  if (
    !input ||
    typeof input.materialId !== 'string' ||
    !input.materialId.trim()
  ) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'A valid materialId is required for Stock-In.',
      { field: 'materialId' }
    );
  }

  const materialId = input.materialId.trim();
  const material = state.materials.find((m) => m.id === materialId);
  if (!material) {
    throw new AppDomainError(
      'MATERIAL_NOT_FOUND',
      `Material with ID "${materialId}" was not found.`,
      { materialId }
    );
  }

  const quantityAdded = assertPositiveNumber(
    input.quantityAdded,
    'quantityAdded'
  );
  const unitPurchaseCost = assertNonNegativeNumber(
    input.unitPurchaseCost,
    'unitPurchaseCost'
  );
  const supplierNote = validateOptionalNote(
    input.supplierNote,
    'supplierNote',
    200
  );

  const previousStock = material.currentStock;
  const newStock = round2(previousStock + quantityAdded);
  const totalCost = round2(quantityAdded * unitPurchaseCost);
  const updatedUnitCost = calculateWeightedAverageCost(
    previousStock,
    material.unitCost,
    quantityAdded,
    unitPurchaseCost
  );

  material.currentStock = newStock;
  material.unitCost = updatedUnitCost;
  material.updatedAt = nowIso;

  const stockInRecord: StockInRecord = {
    id: `stkin_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    materialId: material.id,
    materialName: material.name,
    unit: material.unit,
    quantityAdded,
    unitPurchaseCost,
    totalCost,
    previousStock,
    newStock,
    supplierNote,
    createdAt: nowIso,
  };

  state.stockIns.unshift(stockInRecord);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return { stockIn: stockInRecord, material };
}

/**
 * Commits a Physical Ground-Stock Audit reconciliation, updating each audited material's
 * currentStock to match the counted physicalCount on the ground and logging variances
 * (FR-016..FR-019, BR-004, BR-008, VAL-003, VAL-006, VAL-007).
 */
export function recordStockAudit(
  state: ErpState,
  input: CreateAuditInput,
  nowIso: string = new Date().toISOString()
): StockAuditRecord {
  if (!input || !Array.isArray(input.items) || input.items.length === 0) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'A ground-stock audit must include at least one audited material item.',
      { field: 'items' }
    );
  }

  const note = validateOptionalNote(input.note, 'note', 250);

  // Deduplicate by materialId (latest physicalCount wins if repeated) and validate
  const dedupedItems = new Map<string, number>();
  for (const rawItem of input.items) {
    if (
      !rawItem ||
      typeof rawItem.materialId !== 'string' ||
      !rawItem.materialId.trim()
    ) {
      throw new AppDomainError(
        'VALIDATION_ERROR',
        'Each audit item must specify a valid materialId.',
        { field: 'materialId' }
      );
    }
    const materialId = rawItem.materialId.trim();
    const physicalCount = assertNonNegativeNumber(
      rawItem.physicalCount,
      'physicalCount'
    );
    dedupedItems.set(materialId, physicalCount);
  }

  // First pass: validate all materials exist before mutating any stock
  const validatedPlans: Array<{
    material: Material;
    adjustment: AuditLineItem;
  }> = [];

  for (const [materialId, physicalCount] of dedupedItems.entries()) {
    const material = state.materials.find((m) => m.id === materialId);
    if (!material) {
      throw new AppDomainError(
        'MATERIAL_NOT_FOUND',
        `Material with ID "${materialId}" was not found.`,
        { materialId }
      );
    }

    const expectedStock = material.currentStock;
    const variance = round2(physicalCount - expectedStock);

    validatedPlans.push({
      material,
      adjustment: {
        materialId: material.id,
        materialName: material.name,
        unit: material.unit,
        expectedStock,
        physicalCount,
        variance,
        unitCostSnapshot: material.unitCost,
      },
    });
  }

  // Second pass: apply ground-stock reconciliation atomically (BR-008)
  const adjustments: AuditLineItem[] = [];
  for (const plan of validatedPlans) {
    plan.material.currentStock = plan.adjustment.physicalCount;
    plan.material.updatedAt = nowIso;
    adjustments.push(plan.adjustment);
  }

  const auditRecord: StockAuditRecord = {
    id: `audit_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    createdAt: nowIso,
    note,
    adjustments,
  };

  state.audits.unshift(auditRecord);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return auditRecord;
}

/**
 * Creates the deterministic initial seed state for a Construction & Finishing Material Store.
 */
export function createInitialErpState(): ErpState {
  const timestamp = '2026-10-30T08:00:00.000Z';
  const materials: Material[] = [
    {
      id: 'mat_rebar_12',
      name: 'Deformed Rebar 12mm',
      category: MaterialCategory.REBAR,
      specs: 'Ø12mm · Grade 60 · 12m length',
      unit: MaterialUnit.BARS,
      currentStock: 240,
      minStockLevel: 40,
      unitCost: 860,
      defaultSellingPrice: 990,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
    {
      id: 'mat_rebar_16',
      name: 'Deformed Rebar 16mm',
      category: MaterialCategory.REBAR,
      specs: 'Ø16mm · Grade 60 · 12m length',
      unit: MaterialUnit.BARS,
      currentStock: 115,
      minStockLevel: 30,
      unitCost: 1520,
      defaultSellingPrice: 1750,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
    {
      id: 'mat_cement_opc',
      name: 'Dangote Portland Cement 50kg',
      category: MaterialCategory.CEMENT,
      specs: 'OPC 42.5R · 50kg bag',
      unit: MaterialUnit.BAGS,
      currentStock: 180,
      minStockLevel: 50,
      unitCost: 1120,
      defaultSellingPrice: 1280,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
    {
      id: 'mat_tile_60x60',
      name: 'Porcelain Floor Tile 60x60 Ivory',
      category: MaterialCategory.TILES,
      specs: '60x60cm · Glazed Polished · 1.44m²/box',
      unit: MaterialUnit.BOXES,
      currentStock: 18,
      minStockLevel: 25,
      unitCost: 1350,
      defaultSellingPrice: 1620,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
    {
      id: 'mat_paint_20l',
      name: 'Super Acrylic Exterior Wall Paint 20L',
      category: MaterialCategory.PAINT,
      specs: '20L Bucket · Pure White Weatherproof',
      unit: MaterialUnit.BUCKETS,
      currentStock: 32,
      minStockLevel: 10,
      unitCost: 3400,
      defaultSellingPrice: 3950,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
    {
      id: 'mat_wire_bind',
      name: 'Annealed Black Binding Wire',
      category: MaterialCategory.HARDWARE,
      specs: '1.6mm Gauge · Rebar Tie Wire',
      unit: MaterialUnit.KG,
      currentStock: 12,
      minStockLevel: 20,
      unitCost: 210,
      defaultSellingPrice: 265,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
  ];

  const sales: SaleTransaction[] = [];
  const stockIns: StockInRecord[] = [];
  const audits: StockAuditRecord[] = [];

  return {
    materials,
    sales,
    stockIns,
    audits,
    summary: calculateStoreSummary(materials, sales),
  };
}
