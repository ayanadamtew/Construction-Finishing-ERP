import test from 'node:test';
import assert from 'node:assert/strict';
import {
  calculateStoreSummary,
  calculateWeightedAverageCost,
  createCategory,
  createInitialErpState,
  deleteCategory,
  deleteMaterial,
  recordMultiItemSale,
  recordStockAudit,
  recordStockIn,
  registerMaterial,
  reverseSaleTransaction,
  reverseStockAuditRecord,
  reverseStockInRecord,
  round2,
  setMaterialArchivedStatus,
  updateMaterialMetadata,
  validateCategoryAndUnit,
} from './inventoryEngine';
import {
  ActiveSession,
  authenticateUser,
  createAuthorizedUser,
  deleteAuthorizedUser,
  ensureInitialAdminProvisioned,
  hashPassword,
  setAuthorizedUserStatus,
  verifyPassword,
} from './authEngine';
import { MaterialCategory, MaterialUnit } from '../types/erp';
import { AppDomainError } from '../utils/errors';

test('round2 deterministically rounds currency and quantity math to 2 decimal places', () => {
  assert.equal(round2(10.005), 10.01);
  assert.equal(round2(1120.833333), 1120.83);
  assert.equal(round2(0), 0);
});

test('createInitialErpState initializes SKU-free materials and accurate store summary KPIs', () => {
  const state = createInitialErpState();
  assert.equal(state.materials.length, 6);
  assert.equal(state.sales.length, 0);
  assert.equal(state.summary.totalRevenue, 0);
  assert.equal(state.summary.totalProfit, 0);
  assert.equal(state.summary.lowStockCount, 2);
  assert.ok(state.summary.inventoryCostValue > 0);
  assert.ok(state.summary.inventoryRetailValue > state.summary.inventoryCostValue);
});

test('validateCategoryAndUnit accepts valid enums and throws AppDomainError on invalid values', () => {
  const valid = validateCategoryAndUnit('rebar', 'bars');
  assert.equal(valid.category, 'rebar');
  assert.equal(valid.unit, 'bars');

  assert.throws(
    () => validateCategoryAndUnit('invalid_cat', 'bars'),
    (err: unknown) =>
      err instanceof AppDomainError && err.code === 'VALIDATION_ERROR'
  );
});

test('calculateStoreSummary aggregates sales revenue and profit accurately', () => {
  const state = createInitialErpState();
  const summary = calculateStoreSummary(state.materials, [
    {
      id: 'sale_test_1',
      createdAt: '2026-10-31T09:00:00.000Z',
      customerNote: 'Test buyer',
      items: [],
      totalRevenue: 12500.5,
      totalProfit: 1850.25,
    },
  ]);

  assert.equal(summary.totalRevenue, 12500.5);
  assert.equal(summary.totalProfit, 1850.25);
});

test('AC-001: registerMaterial creates a SKU-free material and updates store summary', () => {
  const state = createInitialErpState();
  const initialCostTotal = state.summary.inventoryCostValue;

  const created = registerMaterial(state, {
    name: '  Deformed Rebar 10mm  ',
    category: MaterialCategory.REBAR,
    specs: '  Ø10mm · Grade 60  ',
    unit: MaterialUnit.BARS,
    initialStock: 200,
    minStockLevel: 30,
    unitCost: 850,
    defaultSellingPrice: 980,
  });

  assert.equal(created.name, 'Deformed Rebar 10mm');
  assert.equal(created.specs, 'Ø10mm · Grade 60');
  assert.equal(created.category, MaterialCategory.REBAR);
  assert.equal(created.unit, MaterialUnit.BARS);
  assert.equal(created.currentStock, 200);
  assert.equal(created.unitCost, 850);
  assert.equal(created.defaultSellingPrice, 980);
  assert.equal(state.materials.length, 7);
  assert.equal(
    state.summary.inventoryCostValue,
    round2(initialCostTotal + 200 * 850)
  );
});

test('VAL-001 & VAL-003: registerMaterial rejects empty name and negative numbers', () => {
  const state = createInitialErpState();

  assert.throws(
    () =>
      registerMaterial(state, {
        name: '   ',
        category: MaterialCategory.CEMENT,
        unit: MaterialUnit.BAGS,
        initialStock: 10,
        minStockLevel: 5,
        unitCost: 1000,
        defaultSellingPrice: 1200,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'name'
  );

  assert.throws(
    () =>
      registerMaterial(state, {
        name: 'Mugher Cement 50kg',
        category: MaterialCategory.CEMENT,
        unit: MaterialUnit.BAGS,
        initialStock: -5,
        minStockLevel: 5,
        unitCost: 1000,
        defaultSellingPrice: 1200,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'initialStock'
  );
});

test('FR-003 & FR-004: updateMaterialMetadata updates mutable fields and blocks currentStock tampering', () => {
  const state = createInitialErpState();
  const targetId = state.materials[0].id;

  const updated = updateMaterialMetadata(state, targetId, {
    name: 'Deformed Rebar 12mm (Grade 75)',
    specs: 'Ø12mm · Grade 75 · 12m length',
    minStockLevel: 50,
    defaultSellingPrice: 1040,
  });

  assert.equal(updated.name, 'Deformed Rebar 12mm (Grade 75)');
  assert.equal(updated.minStockLevel, 50);
  assert.equal(updated.defaultSellingPrice, 1040);
  assert.equal(updated.currentStock, 240);

  assert.throws(
    () =>
      updateMaterialMetadata(state, targetId, {
        defaultSellingPrice: 1050,
        currentStock: 999,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'IMMUTABLE_FIELD_VIOLATION' &&
      err.details?.field === 'currentStock'
  );
});

test('BR-001: updateMaterialMetadata blocks changing unit once material has recorded transactions', () => {
  const state = createInitialErpState();
  const target = state.materials[0];

  state.stockIns.push({
    id: 'stkin_test_1',
    materialId: target.id,
    materialName: target.name,
    unit: target.unit,
    quantityAdded: 50,
    unitPurchaseCost: 860,
    totalCost: 43000,
    previousStock: 190,
    newStock: 240,
    supplierNote: 'Initial batch',
    createdAt: '2026-10-30T10:00:00.000Z',
  });

  assert.throws(
    () =>
      updateMaterialMetadata(state, target.id, {
        unit: MaterialUnit.PCS,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'IMMUTABLE_FIELD_VIOLATION' &&
      err.details?.field === 'unit'
  );
});

test('AC-002: recordMultiItemSale calculates line totals, total revenue, profit, and deducts stock atomically', () => {
  const state = createInitialErpState();
  const cement = state.materials.find((m) => m.id === 'mat_cement_opc')!;
  const rebar12 = state.materials.find((m) => m.id === 'mat_rebar_12')!;
  cement.currentStock = 100;
  cement.unitCost = 1100;
  rebar12.currentStock = 50;
  rebar12.unitCost = 850;

  const sale = recordMultiItemSale(state, {
    customerNote: 'Bole site contractor',
    items: [
      {
        materialId: cement.id,
        quantity: 10,
        unitSellingPrice: 1250,
      },
      {
        materialId: rebar12.id,
        quantity: 5,
        unitSellingPrice: 980,
      },
    ],
  });

  assert.equal(sale.items.length, 2);
  assert.equal(sale.items[0].lineTotal, 12500);
  assert.equal(sale.items[0].lineProfit, 1500);
  assert.equal(sale.items[1].lineTotal, 4900);
  assert.equal(sale.items[1].lineProfit, 650);
  assert.equal(sale.totalRevenue, 17400);
  assert.equal(sale.totalProfit, 2150);

  assert.equal(cement.currentStock, 90);
  assert.equal(rebar12.currentStock, 45);
  assert.equal(state.summary.totalRevenue, 17400);
  assert.equal(state.summary.totalProfit, 2150);
});

test('AC-003 & FAIL-004: recordMultiItemSale strictly blocks oversale and performs zero partial deductions', () => {
  const state = createInitialErpState();
  const rebar12 = state.materials.find((m) => m.id === 'mat_rebar_12')!;
  const tiles = state.materials.find((m) => m.id === 'mat_tile_60x60')!;

  assert.throws(
    () =>
      recordMultiItemSale(state, {
        customerNote: 'Oversale attempt',
        items: [
          {
            materialId: rebar12.id,
            quantity: 10,
            unitSellingPrice: 990,
          },
          {
            materialId: tiles.id,
            quantity: 19,
            unitSellingPrice: 1620,
          },
        ],
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'INSUFFICIENT_STOCK' &&
      err.details?.materialId === tiles.id &&
      err.details?.requested === 19 &&
      err.details?.available === 18
  );

  assert.equal(rebar12.currentStock, 240);
  assert.equal(tiles.currentStock, 18);
  assert.equal(state.sales.length, 0);
});

test('BR-003: recordMultiItemSale aggregates duplicate materialId lines and blocks if combined quantity exceeds stock', () => {
  const state = createInitialErpState();
  const tiles = state.materials.find((m) => m.id === 'mat_tile_60x60')!;

  assert.throws(
    () =>
      recordMultiItemSale(state, {
        items: [
          { materialId: tiles.id, quantity: 10, unitSellingPrice: 1620 },
          { materialId: tiles.id, quantity: 10, unitSellingPrice: 1620 },
        ],
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'INSUFFICIENT_STOCK' &&
      err.details?.requested === 20 &&
      err.details?.available === 18
  );

  assert.equal(tiles.currentStock, 18);
});

test('AC-004 & BR-006: recordStockIn increments stock, calculates weighted-average unitCost, and logs StockInRecord', () => {
  const state = createInitialErpState();
  const cement = state.materials.find((m) => m.id === 'mat_cement_opc')!;
  cement.currentStock = 100;
  cement.unitCost = 1000;

  const { stockIn, material } = recordStockIn(state, {
    materialId: cement.id,
    quantityAdded: 100,
    unitPurchaseCost: 1200,
    supplierNote: 'Dangote Factory Truck #402',
  });

  assert.equal(stockIn.previousStock, 100);
  assert.equal(stockIn.newStock, 200);
  assert.equal(stockIn.totalCost, 120000);
  assert.equal(material.currentStock, 200);
  assert.equal(material.unitCost, 1100); // Weighted average of (100*1000 + 100*1200)/200
  assert.equal(state.stockIns.length, 1);
});

test('BR-006 & BR-007: recordStockIn handles zero previousStock and preserves historical sale profit', () => {
  const state = createInitialErpState();
  const wire = state.materials.find((m) => m.id === 'mat_wire_bind')!;
  wire.currentStock = 10;
  wire.unitCost = 200;

  // Sell all 10 kg at 260 ETB (Profit = 10 * (260 - 200) = 600 ETB)
  const completedSale = recordMultiItemSale(state, {
    items: [{ materialId: wire.id, quantity: 10, unitSellingPrice: 260 }],
  });
  assert.equal(wire.currentStock, 0);
  assert.equal(completedSale.totalProfit, 600);

  // Now restock 50 kg at a new supplier cost of 240 ETB when previousStock == 0
  const { material } = recordStockIn(state, {
    materialId: wire.id,
    quantityAdded: 50,
    unitPurchaseCost: 240,
  });

  assert.equal(material.currentStock, 50);
  assert.equal(material.unitCost, 240);
  // Historical sale profit must remain 600 ETB (BR-007)
  assert.equal(state.sales[0].totalProfit, 600);
  assert.equal(state.summary.totalProfit, 600);
});

test('VAL-003 & VAL-004: recordStockIn rejects non-positive quantityAdded or negative unitPurchaseCost', () => {
  assert.equal(calculateWeightedAverageCost(0, 800, 50, 900), 900);

  const state = createInitialErpState();
  const cement = state.materials.find((m) => m.id === 'mat_cement_opc')!;

  assert.throws(
    () =>
      recordStockIn(state, {
        materialId: cement.id,
        quantityAdded: 0,
        unitPurchaseCost: 1100,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'quantityAdded'
  );

  assert.throws(
    () =>
      recordStockIn(state, {
        materialId: cement.id,
        quantityAdded: 25,
        unitPurchaseCost: -10,
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'unitPurchaseCost'
  );
});

test('AC-005 & BR-008: recordStockAudit reconciles physical ground count, computes variance, and leaves unaudited items untouched', () => {
  const state = createInitialErpState();
  const paint = state.materials.find((m) => m.id === 'mat_paint_20l')!;
  const rebar12 = state.materials.find((m) => m.id === 'mat_rebar_12')!;
  const cement = state.materials.find((m) => m.id === 'mat_cement_opc')!;

  // Set paint expected stock to 25 buckets to match AC-005 scenario
  paint.currentStock = 25;
  const untouchedCementStock = cement.currentStock;

  const audit = recordStockAudit(
    state,
    {
      note: '2 buckets damaged in yard, +3 rebar bars found in rack',
      items: [
        { materialId: paint.id, physicalCount: 23 },
        { materialId: rebar12.id, physicalCount: 243 },
      ],
    },
    '2026-10-31T14:00:00.000Z'
  );

  // Verify paint adjustment (25 -> 23, variance -2)
  const paintAdj = audit.adjustments.find((a) => a.materialId === paint.id)!;
  assert.equal(paintAdj.expectedStock, 25);
  assert.equal(paintAdj.physicalCount, 23);
  assert.equal(paintAdj.variance, -2);
  assert.equal(paint.currentStock, 23);

  // Verify rebar12 adjustment (240 -> 243, variance +3)
  const rebarAdj = audit.adjustments.find((a) => a.materialId === rebar12.id)!;
  assert.equal(rebarAdj.expectedStock, 240);
  assert.equal(rebarAdj.physicalCount, 243);
  assert.equal(rebarAdj.variance, 3);
  assert.equal(rebar12.currentStock, 243);

  // BR-008: Unaudited material (cement) must remain untouched
  assert.equal(cement.currentStock, untouchedCementStock);
  assert.equal(state.audits.length, 1);
  assert.equal(state.audits[0].id, audit.id);
});

test('VAL-003, VAL-006 & VAL-007: recordStockAudit rejects empty batch, negative physicalCount, and unknown materialId', () => {
  const state = createInitialErpState();
  const paint = state.materials.find((m) => m.id === 'mat_paint_20l')!;

  // Empty batch (VAL-006)
  assert.throws(
    () => recordStockAudit(state, { items: [] }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'items'
  );

  // Negative physicalCount (VAL-003)
  assert.throws(
    () =>
      recordStockAudit(state, {
        items: [{ materialId: paint.id, physicalCount: -1 }],
      }),
    (err: unknown) =>
      err instanceof AppDomainError &&
      err.code === 'VALIDATION_ERROR' &&
      err.details?.field === 'physicalCount'
  );

  // Unknown materialId (VAL-007)
  assert.throws(
    () =>
      recordStockAudit(state, {
        items: [{ materialId: 'mat_non_existent', physicalCount: 10 }],
      }),
    (err: unknown) =>
      err instanceof AppDomainError && err.code === 'MATERIAL_NOT_FOUND'
  );
});

test('FEATURE 1: AuthEngine hashes passwords securely, authenticates pre-registered users, and prevents last-admin deletion/deactivation', () => {
  const hash = hashPassword('StrongPass#2026');
  assert.ok(!hash.includes('StrongPass#2026'));
  assert.equal(verifyPassword('StrongPass#2026', hash), true);
  assert.equal(verifyPassword('WrongPass', hash), false);

  const state = createInitialErpState();
  const sessions = new Map<string, ActiveSession>();
  ensureInitialAdminProvisioned(state);
  assert.equal(state.users!.length, 1);
  assert.equal(state.users![0].role, 'admin');
  assert.equal(state.users![0].isActive, true);
  const adminActor = state.users![0];

  // Successful login
  const defaultPassword = process.env.ERP_ADMIN_PASSWORD?.trim() || 'Admin@12345';
  const defaultUsername = process.env.ERP_ADMIN_USERNAME?.trim() || 'admin';
  const authed = authenticateUser(state, sessions, {
    username: defaultUsername,
    password: defaultPassword,
  });
  assert.equal(authed.user.username, defaultUsername);

  // Incorrect username
  assert.throws(
    () => authenticateUser(state, sessions, { username: 'nonexistent', password: defaultPassword }),
    (err: unknown) => err instanceof AppDomainError && err.code === 'INVALID_CREDENTIALS'
  );

  // Incorrect password
  assert.throws(
    () => authenticateUser(state, sessions, { username: defaultUsername, password: 'WrongPassword!' }),
    (err: unknown) => err instanceof AppDomainError && err.code === 'INVALID_CREDENTIALS'
  );

  // Empty credentials
  assert.throws(
    () => authenticateUser(state, sessions, { username: '   ', password: '' }),
    (err: unknown) => err instanceof AppDomainError && err.code === 'VALIDATION_ERROR'
  );

  // Last active admin protection: cannot deactivate or delete the sole active admin
  assert.throws(
    () => setAuthorizedUserStatus(state, sessions, adminActor, adminActor.id, false),
    (err: unknown) => err instanceof AppDomainError && err.code === 'LAST_ADMIN_PROTECTION'
  );
  assert.throws(
    () => deleteAuthorizedUser(state, sessions, adminActor, adminActor.id),
    (err: unknown) => err instanceof AppDomainError && err.code === 'LAST_ADMIN_PROTECTION'
  );

  // Create a staff account, deactivate it, and verify login is blocked
  const staff = createAuthorizedUser(state, adminActor, {
    username: 'cashier1',
    displayName: 'Store Cashier',
    password: 'CashierPassword123',
    role: 'staff',
  });
  assert.equal(state.users!.length, 2);

  setAuthorizedUserStatus(state, sessions, adminActor, staff.id, false);
  assert.throws(
    () => authenticateUser(state, sessions, { username: 'cashier1', password: 'CashierPassword123' }),
    (err: unknown) => err instanceof AppDomainError && err.code === 'ACCOUNT_DEACTIVATED'
  );

  // Deleting staff user succeeds
  const deletedId = deleteAuthorizedUser(state, sessions, adminActor, staff.id);
  assert.equal(deletedId, staff.id);
  assert.equal(state.users!.length, 1);
});

test('FEATURE 2A: deleteMaterial deletes unused material, blocks deleting material with history, and supports archiving', () => {
  const state = createInitialErpState();
  const unusedMat = state.materials.find((m) => m.id === 'mat_wire_bind')!;
  const usedMat = state.materials.find((m) => m.id === 'mat_cement_opc')!;

  // Delete unused material succeeds
  const deletedId = deleteMaterial(state, unusedMat.id);
  assert.equal(deletedId, unusedMat.id);
  assert.equal(state.materials.some((m) => m.id === unusedMat.id), false);

  // Record a sale on usedMat so it has transaction history
  recordMultiItemSale(state, {
    items: [{ materialId: usedMat.id, quantity: 5, unitSellingPrice: 1300 }],
  });

  // Attempting to delete material with history throws MATERIAL_HAS_HISTORY
  assert.throws(
    () => deleteMaterial(state, usedMat.id),
    (err: unknown) => err instanceof AppDomainError && err.code === 'MATERIAL_HAS_HISTORY'
  );

  // Archiving material with history succeeds and excludes it from new transactions
  const archived = setMaterialArchivedStatus(state, usedMat.id, true);
  assert.equal(archived.isArchived, true);

  assert.throws(
    () =>
      recordMultiItemSale(state, {
        items: [{ materialId: usedMat.id, quantity: 1, unitSellingPrice: 1300 }],
      }),
    (err: unknown) => err instanceof AppDomainError && err.code === 'MATERIAL_ARCHIVED'
  );
});

test('FEATURE 2B: createCategory and deleteCategory allow deleting unused categories and block deleting categories in use', () => {
  const state = createInitialErpState();

  const customCat = createCategory(state, { name: 'Plumbing & PVC Pipes' });
  assert.equal(customCat.id, 'plumbing_pvc_pipes');

  // Unused category can be deleted
  const removedId = deleteCategory(state, customCat.id);
  assert.equal(removedId, customCat.id);

  // Category in use by existing materials cannot be deleted
  assert.throws(
    () => deleteCategory(state, MaterialCategory.CEMENT),
    (err: unknown) => err instanceof AppDomainError && err.code === 'CATEGORY_IN_USE'
  );
});

test('FEATURE 2C, 2D, 2E: Reversing Sales, Stock-In, and Audits restores stock accurately and blocks duplicate reversals', () => {
  const state = createInitialErpState();
  const cement = state.materials.find((m) => m.id === 'mat_cement_opc')!;
  const initialStock = cement.currentStock; // 180
  const initialCost = cement.unitCost; // 1120

  // 1. Sale Reversal
  const sale = recordMultiItemSale(
    state,
    {
      items: [{ materialId: cement.id, quantity: 10, unitSellingPrice: 1300 }],
      customerNote: 'Walk-in buyer',
    },
    '2026-10-31T10:00:00.000Z',
    'admin'
  );
  assert.equal(cement.currentStock, initialStock - 10);
  assert.equal(state.summary.totalRevenue, 13000);

  const reversedSale = reverseSaleTransaction(
    state,
    sale.id,
    'Customer returned unopened bags',
    'admin'
  );
  assert.equal(reversedSale.isReversed, true);
  assert.equal(reversedSale.reversedBy, 'admin');
  assert.equal(reversedSale.reversalReason, 'Customer returned unopened bags');
  assert.equal(cement.currentStock, initialStock);
  assert.equal(state.summary.totalRevenue, 0);

  // Duplicate sale reversal blocked
  assert.throws(
    () => reverseSaleTransaction(state, sale.id, 'Second attempt', 'admin'),
    (err: unknown) => err instanceof AppDomainError && err.code === 'ALREADY_REVERSED'
  );

  // 2. Stock-In Reversal
  const { stockIn } = recordStockIn(
    state,
    {
      materialId: cement.id,
      quantityAdded: 20,
      unitPurchaseCost: 1220,
    },
    '2026-10-31T11:00:00.000Z',
    'admin'
  );
  assert.equal(cement.currentStock, initialStock + 20);
  assert.notEqual(cement.unitCost, initialCost);

  const { stockIn: reversedStockIn } = reverseStockInRecord(
    state,
    stockIn.id,
    'Wrong supplier batch logged',
    'admin'
  );
  assert.equal(reversedStockIn.isReversed, true);
  assert.equal(cement.currentStock, initialStock);
  assert.equal(cement.unitCost, initialCost);

  // Duplicate stock-in reversal blocked
  assert.throws(
    () => reverseStockInRecord(state, stockIn.id, 'Duplicate', 'admin'),
    (err: unknown) => err instanceof AppDomainError && err.code === 'ALREADY_REVERSED'
  );

  // 3. Stock Audit Reversal
  const audit = recordStockAudit(
    state,
    {
      items: [{ materialId: cement.id, physicalCount: initialStock - 5 }],
      note: 'Miscounted pallet',
    },
    '2026-10-31T12:00:00.000Z',
    'admin'
  );
  assert.equal(cement.currentStock, initialStock - 5);

  const reversedAudit = reverseStockAuditRecord(
    state,
    audit.id,
    'Found missing 5 bags in back storage',
    'admin'
  );
  assert.equal(reversedAudit.isReversed, true);
  assert.equal(cement.currentStock, initialStock);

  // Duplicate audit reversal blocked
  assert.throws(
    () => reverseStockAuditRecord(state, audit.id, 'Duplicate', 'admin'),
    (err: unknown) => err instanceof AppDomainError && err.code === 'ALREADY_REVERSED'
  );
});


