import {
  ALLOWED_CATEGORIES,
  ALLOWED_UNITS,
  AuditLineItem,
  CategoryItem,
  CreateAuditInput,
  CreateCategoryInput,
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
 * Validates required reversal reason (1..200 chars after trim).
 */
export function validateRequiredReversalReason(reason: unknown): string {
  if (typeof reason !== 'string' || !reason.trim()) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'A reversal reason is required to reverse a completed transaction.',
      { field: 'reason' }
    );
  }
  const trimmed = reason.trim();
  if (trimmed.length > 200) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Reversal reason must not exceed 200 characters.',
      { field: 'reason' }
    );
  }
  return trimmed;
}

/**
 * Creates the default category items for a Construction & Finishing Material Store.
 */
export function createDefaultCategories(
  timestamp: string = '2026-10-30T08:00:00.000Z'
): CategoryItem[] {
  const labels: Record<MaterialCategory, string> = {
    [MaterialCategory.REBAR]: 'Rebar',
    [MaterialCategory.CEMENT]: 'Cement',
    [MaterialCategory.TILES]: 'Tiles',
    [MaterialCategory.PAINT]: 'Paint',
    [MaterialCategory.HARDWARE]: 'Hardware',
    [MaterialCategory.OTHER]: 'Other',
  };
  return ALLOWED_CATEGORIES.map((id) => ({
    id,
    name: labels[id],
    isSystemDefault: true,
    createdAt: timestamp,
  }));
}

/**
 * Ensures state.categories is initialized.
 */
export function ensureCategoriesInitialized(
  state: ErpState,
  nowIso: string = '2026-10-30T08:00:00.000Z'
): CategoryItem[] {
  if (!Array.isArray(state.categories) || state.categories.length === 0) {
    state.categories = createDefaultCategories(nowIso);
  }
  return state.categories;
}

/**
 * Computes the derived StoreSummary KPIs from canonical state (FR-020).
 * Excludes reversed sales from totalRevenue and totalProfit, and excludes
 * archived materials from active low-stock alerts.
 */
export function calculateStoreSummary(
  materials: Material[],
  sales: SaleTransaction[]
): StoreSummary {
  const activeSales = sales.filter((sale) => !sale.isReversed);
  const totalRevenue = round2(
    activeSales.reduce((sum, sale) => sum + sale.totalRevenue, 0)
  );
  const totalProfit = round2(
    activeSales.reduce((sum, sale) => sum + sale.totalProfit, 0)
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
    (mat) => !mat.isArchived && mat.currentStock <= mat.minStockLevel
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
 * Validates that a material category and tracking unit belong to allowed enums
 * or registered store categories (VAL-002).
 */
export function validateCategoryAndUnit(
  category: string,
  unit: string,
  registeredCategories?: CategoryItem[]
): { category: MaterialCategory | string; unit: MaterialUnit } {
  const allowedCategoryIds = new Set<string>(ALLOWED_CATEGORIES);
  if (Array.isArray(registeredCategories)) {
    for (const c of registeredCategories) {
      allowedCategoryIds.add(c.id);
    }
  }

  if (!category || !allowedCategoryIds.has(category)) {
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
    category,
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
  ensureCategoriesInitialized(state, nowIso);
  const name = validateMaterialName(input.name);
  const specs = validateMaterialSpecs(input.specs);
  const { category, unit } = validateCategoryAndUnit(
    String(input.category ?? ''),
    String(input.unit ?? ''),
    state.categories
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
    isArchived: false,
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
  ensureCategoriesInitialized(state, nowIso);
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
    nextUnitStr,
    state.categories
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
 * Permanently deletes a material ONLY if it has never been used in any
 * sales, stock-in, or ground-stock audit transactions.
 * If transaction history exists, throws MATERIAL_HAS_HISTORY (409) and instructs
 * the user to archive/deactivate the material instead.
 */
export function deleteMaterial(state: ErpState, materialId: string): string {
  const index = state.materials.findIndex((m) => m.id === materialId);
  if (index === -1) {
    throw new AppDomainError(
      'MATERIAL_NOT_FOUND',
      `Material with ID "${materialId}" was not found.`,
      { materialId }
    );
  }

  const material = state.materials[index];
  if (materialHasTransactions(state, materialId)) {
    throw new AppDomainError(
      'MATERIAL_HAS_HISTORY',
      `Cannot permanently delete "${material.name}" because it has recorded inventory transactions (sales, stock-in, or audits). Archive this material instead so historical records remain intact.`,
      {
        materialId: material.id,
        materialName: material.name,
      }
    );
  }

  state.materials.splice(index, 1);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return material.id;
}

/**
 * Archives (deactivates) or restores a material so historical transactions remain intact
 * while preventing new transactions on archived items.
 */
export function setMaterialArchivedStatus(
  state: ErpState,
  materialId: string,
  isArchived: boolean,
  actorUsername: string = 'admin',
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

  material.isArchived = Boolean(isArchived);
  material.archivedAt = isArchived ? nowIso : undefined;
  material.archivedBy = isArchived ? actorUsername : undefined;
  material.updatedAt = nowIso;

  state.summary = calculateStoreSummary(state.materials, state.sales);
  return material;
}

/**
 * Creates a material category in the store catalog.
 */
export function createCategory(
  state: ErpState,
  input: CreateCategoryInput,
  nowIso: string = new Date().toISOString()
): CategoryItem {
  ensureCategoriesInitialized(state, nowIso);
  const rawName = typeof input?.name === 'string' ? input.name.trim() : '';
  if (rawName.length < 2 || rawName.length > 50) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Category name must be between 2 and 50 characters.',
      { field: 'name' }
    );
  }

  const rawId =
    typeof input?.id === 'string' && input.id.trim()
      ? input.id.trim().toLowerCase()
      : rawName
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_+|_+$/g, '');

  if (!rawId) {
    throw new AppDomainError(
      'VALIDATION_ERROR',
      'Category ID must contain valid alphanumeric characters.',
      { field: 'id' }
    );
  }

  const exists = state.categories!.some(
    (c) =>
      c.id.toLowerCase() === rawId ||
      c.name.toLowerCase() === rawName.toLowerCase()
  );
  if (exists) {
    throw new AppDomainError(
      'DUPLICATE_RECORD',
      `Category "${rawName}" already exists.`,
      { categoryId: rawId, field: 'name' }
    );
  }

  const created: CategoryItem = {
    id: rawId,
    name: rawName,
    isSystemDefault: false,
    createdAt: nowIso,
  };

  state.categories!.push(created);
  return created;
}

/**
 * Deletes a category ONLY when no existing materials (active or archived) use it.
 */
export function deleteCategory(state: ErpState, categoryId: string): string {
  ensureCategoriesInitialized(state);
  const normalizedId = String(categoryId ?? '').trim();
  const index = state.categories!.findIndex((c) => c.id === normalizedId);
  if (index === -1) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `Category "${normalizedId}" was not found.`,
      { categoryId: normalizedId }
    );
  }

  const category = state.categories![index];
  const materialsUsingCategory = state.materials.filter(
    (m) => m.category === normalizedId
  );

  if (materialsUsingCategory.length > 0) {
    throw new AppDomainError(
      'CATEGORY_IN_USE',
      `Cannot delete category "${category.name}" because it is currently used by ${materialsUsingCategory.length} material(s). Reassign or remove those materials first.`,
      {
        categoryId: category.id,
        inUseCount: materialsUsingCategory.length,
      }
    );
  }

  state.categories!.splice(index, 1);
  return category.id;
}

/**
 * Executes an atomic multi-item sale transaction with strict stock-floor blocking
 * and aggregate duplicate-line protection (FR-006..FR-012, BR-002, BR-003, FAIL-004).
 */
export function recordMultiItemSale(
  state: ErpState,
  input: CreateSaleInput,
  nowIso: string = new Date().toISOString(),
  actorUsername?: string
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

    if (material.isArchived) {
      throw new AppDomainError(
        'MATERIAL_ARCHIVED',
        `Material "${material.name}" is archived and cannot be sold. Restore it first.`,
        { materialId: material.id, materialName: material.name }
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
    createdBy: actorUsername,
    isReversed: false,
  };

  state.sales.unshift(saleTransaction);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return saleTransaction;
}

/**
 * Reverses/cancels a completed sale transaction atomically:
 * - Never deletes the sale record
 * - Prevents duplicate reversals
 * - Restores corresponding inventory quantities
 * - Records reversal reason, timestamp, and responsible user
 */
export function reverseSaleTransaction(
  state: ErpState,
  saleId: string,
  reason: unknown,
  actorUsername: string = 'admin',
  nowIso: string = new Date().toISOString()
): SaleTransaction {
  const validatedReason = validateRequiredReversalReason(reason);

  const sale = state.sales.find((s) => s.id === saleId);
  if (!sale) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `Sale transaction "${saleId}" was not found.`,
      { recordId: saleId }
    );
  }

  if (sale.isReversed) {
    throw new AppDomainError(
      'ALREADY_REVERSED',
      `Sale transaction "${saleId}" has already been reversed.`,
      { recordId: saleId }
    );
  }

  // First pass: verify all referenced materials exist in the catalog
  const restorePlans: Array<{ material: Material; quantity: number }> = [];
  for (const item of sale.items) {
    const material = state.materials.find((m) => m.id === item.materialId);
    if (!material) {
      throw new AppDomainError(
        'MATERIAL_NOT_FOUND',
        `Material "${item.materialName}" (${item.materialId}) was not found for sale reversal.`,
        { materialId: item.materialId, materialName: item.materialName }
      );
    }
    restorePlans.push({ material, quantity: item.quantity });
  }

  // Second pass: atomically restore stock balances
  for (const plan of restorePlans) {
    plan.material.currentStock = round2(
      plan.material.currentStock + plan.quantity
    );
    plan.material.updatedAt = nowIso;
  }

  sale.isReversed = true;
  sale.reversedAt = nowIso;
  sale.reversedBy = actorUsername;
  sale.reversalReason = validatedReason;

  state.summary = calculateStoreSummary(state.materials, state.sales);
  return sale;
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
  nowIso: string = new Date().toISOString(),
  actorUsername?: string
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

  if (material.isArchived) {
    throw new AppDomainError(
      'MATERIAL_ARCHIVED',
      `Material "${material.name}" is archived and cannot receive new stock-in deliveries. Restore it first.`,
      { materialId: material.id, materialName: material.name }
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
  const previousUnitCost = material.unitCost;
  const newStock = round2(previousStock + quantityAdded);
  const totalCost = round2(quantityAdded * unitPurchaseCost);
  const updatedUnitCost = calculateWeightedAverageCost(
    previousStock,
    previousUnitCost,
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
    previousUnitCost,
    supplierNote,
    createdAt: nowIso,
    createdBy: actorUsername,
    isReversed: false,
  };

  state.stockIns.unshift(stockInRecord);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return { stockIn: stockInRecord, material };
}

/**
 * Reverses a completed Stock-In transaction atomically:
 * - Never deletes the Stock-In record
 * - Prevents duplicate reversals
 * - Blocks reversal if current ground stock is less than quantityAdded (INSUFFICIENT_STOCK_FOR_REVERSAL)
 * - Deducts quantityAdded and restores previous unit cost safely
 */
export function reverseStockInRecord(
  state: ErpState,
  stockInId: string,
  reason: unknown,
  actorUsername: string = 'admin',
  nowIso: string = new Date().toISOString()
): { stockIn: StockInRecord; material: Material } {
  const validatedReason = validateRequiredReversalReason(reason);

  const stockIn = state.stockIns.find((rec) => rec.id === stockInId);
  if (!stockIn) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `Stock-In record "${stockInId}" was not found.`,
      { recordId: stockInId }
    );
  }

  if (stockIn.isReversed) {
    throw new AppDomainError(
      'ALREADY_REVERSED',
      `Stock-In record "${stockInId}" has already been reversed.`,
      { recordId: stockInId }
    );
  }

  const material = state.materials.find((m) => m.id === stockIn.materialId);
  if (!material) {
    throw new AppDomainError(
      'MATERIAL_NOT_FOUND',
      `Material "${stockIn.materialName}" (${stockIn.materialId}) was not found.`,
      { materialId: stockIn.materialId, materialName: stockIn.materialName }
    );
  }

  if (material.currentStock < stockIn.quantityAdded) {
    throw new AppDomainError(
      'INSUFFICIENT_STOCK_FOR_REVERSAL',
      `Cannot reverse Stock-In of ${stockIn.quantityAdded} ${stockIn.unit} for "${material.name}" because current stock is only ${material.currentStock} ${material.unit}.`,
      {
        recordId: stockIn.id,
        materialId: material.id,
        materialName: material.name,
        requested: stockIn.quantityAdded,
        available: material.currentStock,
        unit: material.unit,
      }
    );
  }

  material.currentStock = round2(material.currentStock - stockIn.quantityAdded);
  if (
    typeof stockIn.previousUnitCost === 'number' &&
    stockIn.previousUnitCost >= 0
  ) {
    material.unitCost = round2(stockIn.previousUnitCost);
  }
  material.updatedAt = nowIso;

  stockIn.isReversed = true;
  stockIn.reversedAt = nowIso;
  stockIn.reversedBy = actorUsername;
  stockIn.reversalReason = validatedReason;

  state.summary = calculateStoreSummary(state.materials, state.sales);
  return { stockIn, material };
}

/**
 * Commits a Physical Ground-Stock Audit reconciliation, updating each audited material's
 * currentStock to match the counted physicalCount on the ground and logging variances
 * (FR-016..FR-019, BR-004, BR-008, VAL-003, VAL-006, VAL-007).
 */
export function recordStockAudit(
  state: ErpState,
  input: CreateAuditInput,
  nowIso: string = new Date().toISOString(),
  actorUsername?: string
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

    if (material.isArchived) {
      throw new AppDomainError(
        'MATERIAL_ARCHIVED',
        `Material "${material.name}" is archived and cannot be included in a ground-stock audit. Restore it first.`,
        { materialId: material.id, materialName: material.name }
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
    createdBy: actorUsername,
    isReversed: false,
  };

  state.audits.unshift(auditRecord);
  state.summary = calculateStoreSummary(state.materials, state.sales);
  return auditRecord;
}

/**
 * Reverses a completed Ground-Stock Audit record atomically:
 * - Never deletes the completed audit record
 * - Prevents duplicate reversals
 * - Applies the inverse variance (-adj.variance) to each material if stock floor >= 0 permits
 */
export function reverseStockAuditRecord(
  state: ErpState,
  auditId: string,
  reason: unknown,
  actorUsername: string = 'admin',
  nowIso: string = new Date().toISOString()
): StockAuditRecord {
  const validatedReason = validateRequiredReversalReason(reason);

  const audit = state.audits.find((a) => a.id === auditId);
  if (!audit) {
    throw new AppDomainError(
      'RECORD_NOT_FOUND',
      `Ground-stock audit record "${auditId}" was not found.`,
      { recordId: auditId }
    );
  }

  if (audit.isReversed) {
    throw new AppDomainError(
      'ALREADY_REVERSED',
      `Ground-stock audit record "${auditId}" has already been reversed.`,
      { recordId: auditId }
    );
  }

  const reversalPlans: Array<{ material: Material; nextStock: number }> = [];
  for (const adj of audit.adjustments) {
    const material = state.materials.find((m) => m.id === adj.materialId);
    if (!material) {
      throw new AppDomainError(
        'MATERIAL_NOT_FOUND',
        `Material "${adj.materialName}" (${adj.materialId}) was not found for audit reversal.`,
        { materialId: adj.materialId, materialName: adj.materialName }
      );
    }

    const nextStock = round2(material.currentStock - adj.variance);
    if (nextStock < 0) {
      throw new AppDomainError(
        'INSUFFICIENT_STOCK_FOR_REVERSAL',
        `Cannot reverse audit adjustment for "${material.name}" because reversing surplus variance (+${adj.variance}) would drop current stock (${material.currentStock}) below 0.`,
        {
          recordId: audit.id,
          materialId: material.id,
          materialName: material.name,
          requested: adj.variance,
          available: material.currentStock,
          unit: material.unit,
        }
      );
    }
    reversalPlans.push({ material, nextStock });
  }

  for (const plan of reversalPlans) {
    plan.material.currentStock = plan.nextStock;
    plan.material.updatedAt = nowIso;
  }

  audit.isReversed = true;
  audit.reversedAt = nowIso;
  audit.reversedBy = actorUsername;
  audit.reversalReason = validatedReason;

  state.summary = calculateStoreSummary(state.materials, state.sales);
  return audit;
}

export const KNOWN_SAMPLE_MATERIAL_IDS = new Set<string>([
  'mat_rebar_12',
  'mat_rebar_16',
  'mat_cement_opc',
  'mat_tile_60x60',
  'mat_paint_20l',
  'mat_wire_bind',
  'mat-rebar-12mm',
  'mat-rebar-16mm',
  'mat-cement-dangote',
  'mat-cement-derba',
  'mat-tiles-porcelain-60',
  'mat-paint-kadisco-white',
  'mat-hardware-binding-wire',
]);

/**
 * Returns deterministic sample materials strictly for automated unit tests.
 * Never used in production initialization.
 */
export function createDemoSeedMaterials(
  timestamp: string = '2026-10-30T08:00:00.000Z'
): Material[] {
  return [
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
      isArchived: false,
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
      isArchived: false,
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
      isArchived: false,
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
      isArchived: false,
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
      isArchived: false,
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
      isArchived: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    },
  ];
}

/**
 * Creates the initial ERP state.
 * In production (default), no sample/demo materials or transactions are seeded.
 * Pass `{ seedDemoData: true }` only in automated test suites.
 */
export function createInitialErpState(options?: {
  seedDemoData?: boolean;
}): ErpState {
  const timestamp = '2026-10-30T08:00:00.000Z';
  const categories = createDefaultCategories(timestamp);
  const materials: Material[] = options?.seedDemoData
    ? createDemoSeedMaterials(timestamp)
    : [];

  const sales: SaleTransaction[] = [];
  const stockIns: StockInRecord[] = [];
  const audits: StockAuditRecord[] = [];

  return {
    materials,
    categories,
    sales,
    stockIns,
    audits,
    summary: calculateStoreSummary(materials, sales),
  };
}

