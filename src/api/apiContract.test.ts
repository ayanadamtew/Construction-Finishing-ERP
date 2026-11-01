import assert from 'node:assert/strict';
import { Server } from 'node:http';
import { AddressInfo } from 'node:net';
import { afterEach, beforeEach, describe, it } from 'node:test';
import { createErpApiApp } from '../../server';
import { createInitialErpState } from '../domain/inventoryEngine';
import {
  ApiErrorEnvelope,
  CategoryMutationResponse,
  CreateAuditResponse,
  CreateSaleResponse,
  CreateStockInResponse,
  DeleteMaterialResponse,
  ErpState,
  LoginResponse,
  MaterialCategory,
  MaterialMutationResponse,
  MaterialUnit,
  ReverseAuditResponse,
  ReverseSaleResponse,
  ReverseStockInResponse,
  PublicUser,
} from '../types/erp';

/**
 * Automated HTTP API Contract & Structured Error-Envelope Test Suite
 * Verifies all endpoints and error codes defined in docs/API_CONTRACT.md
 * without mutating the persistent disk store.
 */
describe('HTTP API Contract & Error Envelopes (docs/API_CONTRACT.md)', () => {
  let server: Server;
  let baseUrl: string;
  let persistCallCount: number;
  let authToken: string;

  const defaultAdminUsername =
    process.env.ERP_ADMIN_USERNAME?.trim() || 'admin';
  const defaultAdminPassword =
    process.env.ERP_ADMIN_PASSWORD?.trim() || 'Admin@12345';

  function authHeaders(extra?: Record<string, string>): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${authToken}`,
      ...(extra ?? {}),
    };
  }

  beforeEach(async () => {
    persistCallCount = 0;
    const freshState = createInitialErpState();
    const { app } = createErpApiApp(freshState, () => {
      persistCallCount += 1;
    });

    await new Promise<void>((resolve) => {
      server = app.listen(0, '127.0.0.1', () => {
        const addr = server.address() as AddressInfo;
        baseUrl = `http://127.0.0.1:${addr.port}`;
        resolve();
      });
    });

    // Authenticate as initial provisioned administrator
    const loginRes = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: defaultAdminUsername,
        password: defaultAdminPassword,
      }),
    });
    assert.equal(loginRes.status, 200);
    const loginData = (await loginRes.json()) as LoginResponse;
    authToken = loginData.token;
    // Reset persistCallCount after initial login setup so individual tests can assert exact counts
    persistCallCount = 0;
  });

  afterEach(async () => {
    if (server) {
      await new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
    }
  });

  it('1. GET /api/state returns 200 OK with initial materials, ledgers, and store summary', async () => {
    const res = await fetch(`${baseUrl}/api/state`, {
      headers: authHeaders(),
    });
    assert.equal(res.status, 200);

    const body = (await res.json()) as ErpState;
    assert.ok(Array.isArray(body.materials));
    assert.equal(body.materials.length, 6);
    assert.ok(Array.isArray(body.sales));
    assert.ok(Array.isArray(body.stockIns));
    assert.ok(Array.isArray(body.audits));
    assert.equal(body.summary.lowStockCount, 2);
    assert.ok(body.summary.inventoryCostValue > 0);
  });

  it('2. POST /api/materials returns 201 Created for SKU-free material registration and 400 VALIDATION_ERROR on invalid payload', async () => {
    // Positive case: SKU-free material registration (AC-001, FR-001, FR-002)
    const createRes = await fetch(`${baseUrl}/api/materials`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        name: 'Spanish Porcelain Floor Tile 60x60',
        category: MaterialCategory.TILES,
        specs: '60x60cm · Matte Finish',
        unit: MaterialUnit.BOXES,
        initialStock: 80,
        minStockLevel: 20,
        unitCost: 950,
        defaultSellingPrice: 1250,
      }),
    });

    assert.equal(createRes.status, 201);
    const createdBody = (await createRes.json()) as MaterialMutationResponse;
    assert.equal(createdBody.material.name, 'Spanish Porcelain Floor Tile 60x60');
    assert.equal(createdBody.material.currentStock, 80);
    assert.equal(createdBody.materials.length, 7);
    assert.equal(persistCallCount, 1);

    // Negative case: Empty material name returns 400 VALIDATION_ERROR
    const invalidRes = await fetch(`${baseUrl}/api/materials`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        name: '   ',
        category: MaterialCategory.CEMENT,
        unit: MaterialUnit.BAGS,
        initialStock: 10,
        minStockLevel: 5,
        unitCost: 1100,
        defaultSellingPrice: 1300,
      }),
    });

    assert.equal(invalidRes.status, 400);
    const errorBody = (await invalidRes.json()) as ApiErrorEnvelope;
    assert.equal(errorBody.error.code, 'VALIDATION_ERROR');
  });

  it('3. PATCH /api/materials/:id returns 200 OK for metadata updates, 400 IMMUTABLE_FIELD_VIOLATION for currentStock/locked unit, and 404 MATERIAL_NOT_FOUND', async () => {
    // Positive metadata update (FR-003)
    const patchRes = await fetch(`${baseUrl}/api/materials/mat_cement_opc`, {
      method: 'PATCH',
      headers: authHeaders(),
      body: JSON.stringify({
        defaultSellingPrice: 1450,
        minStockLevel: 35,
      }),
    });
    assert.equal(patchRes.status, 200);
    const patchBody = (await patchRes.json()) as MaterialMutationResponse;
    assert.equal(patchBody.material.defaultSellingPrice, 1450);
    assert.equal(patchBody.material.minStockLevel, 35);

    // Negative case 1: Attempting to overwrite currentStock via PATCH (BR-001)
    const stockTamperRes = await fetch(
      `${baseUrl}/api/materials/mat_cement_opc`,
      {
        method: 'PATCH',
        headers: authHeaders(),
        body: JSON.stringify({
          currentStock: 999,
        }),
      }
    );
    assert.equal(stockTamperRes.status, 400);
    const tamperError = (await stockTamperRes.json()) as ApiErrorEnvelope;
    assert.equal(tamperError.error.code, 'IMMUTABLE_FIELD_VIOLATION');

    // Negative case 2: Attempting to change unit after a sale transaction exists (FR-004)
    await fetch(`${baseUrl}/api/sales`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          {
            materialId: 'mat_cement_opc',
            quantity: 2,
            unitSellingPrice: 1450,
          },
        ],
        customerNote: 'Tester',
      }),
    });

    const unitChangeRes = await fetch(
      `${baseUrl}/api/materials/mat_cement_opc`,
      {
        method: 'PATCH',
        headers: authHeaders(),
        body: JSON.stringify({
          unit: MaterialUnit.KG,
        }),
      }
    );
    assert.equal(unitChangeRes.status, 400);
    const unitError = (await unitChangeRes.json()) as ApiErrorEnvelope;
    assert.equal(unitError.error.code, 'IMMUTABLE_FIELD_VIOLATION');

    // Negative case 3: Non-existent material ID returns 404 MATERIAL_NOT_FOUND
    const notFoundRes = await fetch(`${baseUrl}/api/materials/mat_unknown_999`, {
      method: 'PATCH',
      headers: authHeaders(),
      body: JSON.stringify({ defaultSellingPrice: 500 }),
    });
    assert.equal(notFoundRes.status, 404);
    const notFoundError = (await notFoundRes.json()) as ApiErrorEnvelope;
    assert.equal(notFoundError.error.code, 'MATERIAL_NOT_FOUND');
  });

  it('4. POST /api/sales records multi-item sales (201) and enforces atomic INSUFFICIENT_STOCK rollback (400)', async () => {
    // Positive multi-item sale (AC-002)
    const saleRes = await fetch(`${baseUrl}/api/sales`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          {
            materialId: 'mat_cement_opc',
            quantity: 5,
            unitSellingPrice: 1280,
          },
          {
            materialId: 'mat_tile_60x60',
            quantity: 2,
            unitSellingPrice: 1620,
          },
        ],
        customerNote: 'Contractor cash purchase',
      }),
    });

    assert.equal(saleRes.status, 201);
    const saleBody = (await saleRes.json()) as CreateSaleResponse;
    assert.equal(saleBody.sale.items.length, 2);
    assert.equal(saleBody.sale.totalRevenue, 5 * 1280 + 2 * 1620);

    const cementAfterSale = saleBody.materials.find(
      (m) => m.id === 'mat_cement_opc'
    );
    assert.equal(cementAfterSale?.currentStock, 175); // 180 - 5

    // Negative case: Over-stock sale across duplicate lines triggers 400 INSUFFICIENT_STOCK and preserves stock at 175 (AC-003, FAIL-004)
    const overSaleRes = await fetch(`${baseUrl}/api/sales`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          {
            materialId: 'mat_tile_60x60',
            quantity: 3,
            unitSellingPrice: 1620,
          },
          {
            materialId: 'mat_cement_opc',
            quantity: 100,
            unitSellingPrice: 1280,
          },
          {
            materialId: 'mat_cement_opc',
            quantity: 80, // 100 + 80 = 180 > 175 available
            unitSellingPrice: 1280,
          },
        ],
        customerNote: 'Oversale attempt',
      }),
    });

    assert.equal(overSaleRes.status, 400);
    const overSaleErr = (await overSaleRes.json()) as ApiErrorEnvelope;
    assert.equal(overSaleErr.error.code, 'INSUFFICIENT_STOCK');
    assert.equal(overSaleErr.error.details?.materialId, 'mat_cement_opc');
    assert.equal(overSaleErr.error.details?.available, 175);
    assert.equal(overSaleErr.error.details?.requested, 180);

    // Verify atomic rollback: tile stock was NOT deducted either
    const stateRes = await fetch(`${baseUrl}/api/state`, {
      headers: authHeaders(),
    });
    const stateBody = (await stateRes.json()) as ErpState;
    const tileAfterFailedSale = stateBody.materials.find(
      (m) => m.id === 'mat_tile_60x60'
    );
    assert.equal(tileAfterFailedSale?.currentStock, 16); // 18 - 2 from first valid sale
  });

  it('5. POST /api/stock-in increments stock with weighted-average cost (201) and rejects non-positive quantities (400)', async () => {
    // Positive Stock-In (AC-004, BR-006): mat_wire_bind starts with currentStock: 12, unitCost: 210
    const stockInRes = await fetch(`${baseUrl}/api/stock-in`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        materialId: 'mat_wire_bind',
        quantityAdded: 12,
        unitPurchaseCost: 250,
        supplierNote: 'Addis Steel Wire Supplier',
      }),
    });

    assert.equal(stockInRes.status, 201);
    const stockInBody = (await stockInRes.json()) as CreateStockInResponse;
    assert.equal(stockInBody.material.currentStock, 24); // 12 + 12
    // Weighted average of (12 * 210 + 12 * 250) / 24 = 230
    assert.equal(stockInBody.material.unitCost, 230);

    // Negative case: quantityAdded <= 0 returns 400 VALIDATION_ERROR (VAL-002)
    const badStockInRes = await fetch(`${baseUrl}/api/stock-in`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        materialId: 'mat_wire_bind',
        quantityAdded: 0,
        unitPurchaseCost: 250,
        supplierNote: 'Invalid zero delivery',
      }),
    });

    assert.equal(badStockInRes.status, 400);
    const badStockInErr = (await badStockInRes.json()) as ApiErrorEnvelope;
    assert.equal(badStockInErr.error.code, 'VALIDATION_ERROR');
  });

  it('6. POST /api/audits reconciles physical ground-stock (201) and rejects negative counts or empty adjustments (400)', async () => {
    // Positive Stock Audit (AC-005, FR-016..FR-019): mat_tile_60x60 starts at 18
    const auditRes = await fetch(`${baseUrl}/api/audits`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          {
            materialId: 'mat_tile_60x60',
            physicalCount: 16, // expectedStock 18 -> variance -2
          },
        ],
        note: '2 broken boxes found during yard inspection',
      }),
    });

    assert.equal(auditRes.status, 201);
    const auditBody = (await auditRes.json()) as CreateAuditResponse;
    assert.equal(auditBody.audit.adjustments.length, 1);
    assert.equal(auditBody.audit.adjustments[0].variance, -2);

    const tileAfterAudit = auditBody.materials.find(
      (m) => m.id === 'mat_tile_60x60'
    );
    assert.equal(tileAfterAudit?.currentStock, 16);

    // Negative case: Negative physicalCount returns 400 VALIDATION_ERROR (VAL-003)
    const badAuditRes = await fetch(`${baseUrl}/api/audits`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          {
            materialId: 'mat_tile_60x60',
            physicalCount: -5,
          },
        ],
        note: 'Invalid negative count',
      }),
    });

    assert.equal(badAuditRes.status, 400);
    const badAuditErr = (await badAuditRes.json()) as ApiErrorEnvelope;
    assert.equal(badAuditErr.error.code, 'VALIDATION_ERROR');
  });

  it('7. FEATURE 1: Login, session verification, unauthorized route protection, logout, and last-admin protection', async () => {
    // Unauthenticated access to /api/state is rejected with 401 UNAUTHORIZED
    const unauthRes = await fetch(`${baseUrl}/api/state`);
    assert.equal(unauthRes.status, 401);
    const unauthErr = (await unauthRes.json()) as ApiErrorEnvelope;
    assert.equal(unauthErr.error.code, 'UNAUTHORIZED');

    // Incorrect username returns 401 INVALID_CREDENTIALS
    const badUserRes = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'unknown_user',
        password: defaultAdminPassword,
      }),
    });
    assert.equal(badUserRes.status, 401);
    const badUserErr = (await badUserRes.json()) as ApiErrorEnvelope;
    assert.equal(badUserErr.error.code, 'INVALID_CREDENTIALS');

    // Incorrect password returns 401 INVALID_CREDENTIALS
    const badPassRes = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: defaultAdminUsername,
        password: 'WrongPassword999',
      }),
    });
    assert.equal(badPassRes.status, 401);

    // Empty credentials return 400 VALIDATION_ERROR
    const emptyCredsRes = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: '',
        password: '',
      }),
    });
    assert.equal(emptyCredsRes.status, 400);

    // Session verification via GET /api/auth/me succeeds with valid token
    const meRes = await fetch(`${baseUrl}/api/auth/me`, {
      headers: authHeaders(),
    });
    assert.equal(meRes.status, 200);

    // Prevent deleting the last active administrator (409 LAST_ADMIN_PROTECTION)
    const usersRes = await fetch(`${baseUrl}/api/users`, {
      headers: authHeaders(),
    });
    assert.equal(usersRes.status, 200);
    const usersBody = (await usersRes.json()) as { users: PublicUser[] };
    const soleAdminId = usersBody.users[0].id;

    const delAdminRes = await fetch(`${baseUrl}/api/users/${soleAdminId}`, {
      method: 'DELETE',
      headers: authHeaders(),
    });
    assert.equal(delAdminRes.status, 409);
    const delAdminErr = (await delAdminRes.json()) as ApiErrorEnvelope;
    assert.equal(delAdminErr.error.code, 'LAST_ADMIN_PROTECTION');

    // Logout invalidates the session token
    const logoutRes = await fetch(`${baseUrl}/api/auth/logout`, {
      method: 'POST',
      headers: authHeaders(),
    });
    assert.equal(logoutRes.status, 200);

    const meAfterLogoutRes = await fetch(`${baseUrl}/api/auth/me`, {
      headers: authHeaders(),
    });
    assert.equal(meAfterLogoutRes.status, 401);
  });

  it('8. FEATURE 2: Material delete/archive, Category delete protection, and Sales/Stock-In/Audit reversals', async () => {
    // A. Delete unused material (mat_wire_bind has no transactions initially)
    const delUnusedRes = await fetch(`${baseUrl}/api/materials/mat_wire_bind`, {
      method: 'DELETE',
      headers: authHeaders(),
    });
    assert.equal(delUnusedRes.status, 200);
    const delUnusedBody = (await delUnusedRes.json()) as DeleteMaterialResponse;
    assert.equal(delUnusedBody.deletedMaterialId, 'mat_wire_bind');
    assert.equal(delUnusedBody.materials.length, 5);

    // Record a sale on mat_cement_opc so it has transaction history
    const saleRes = await fetch(`${baseUrl}/api/sales`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [
          { materialId: 'mat_cement_opc', quantity: 10, unitSellingPrice: 1300 },
        ],
        customerNote: 'Test buyer',
      }),
    });
    assert.equal(saleRes.status, 201);
    const saleBody = (await saleRes.json()) as CreateSaleResponse;

    // Attempting to permanently delete mat_cement_opc fails with 409 MATERIAL_HAS_HISTORY
    const delUsedRes = await fetch(`${baseUrl}/api/materials/mat_cement_opc`, {
      method: 'DELETE',
      headers: authHeaders(),
    });
    assert.equal(delUsedRes.status, 409);
    const delUsedErr = (await delUsedRes.json()) as ApiErrorEnvelope;
    assert.equal(delUsedErr.error.code, 'MATERIAL_HAS_HISTORY');

    // Archiving mat_cement_opc succeeds (200) and unarchiving restores it
    const archiveRes = await fetch(
      `${baseUrl}/api/materials/mat_cement_opc/archive`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ isArchived: true }),
      }
    );
    assert.equal(archiveRes.status, 200);
    const archiveBody = (await archiveRes.json()) as MaterialMutationResponse;
    assert.equal(archiveBody.material.isArchived, true);

    await fetch(`${baseUrl}/api/materials/mat_cement_opc/archive`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ isArchived: false }),
    });

    // B. Categories: Create & delete unused category; block deleting category in use
    const createCatRes = await fetch(`${baseUrl}/api/categories`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ name: 'Roofing Sheets' }),
    });
    assert.equal(createCatRes.status, 201);
    const createCatBody =
      (await createCatRes.json()) as CategoryMutationResponse;
    assert.equal(createCatBody.category?.id, 'roofing_sheets');

    const delCatRes = await fetch(
      `${baseUrl}/api/categories/roofing_sheets`,
      {
        method: 'DELETE',
        headers: authHeaders(),
      }
    );
    assert.equal(delCatRes.status, 200);

    const delUsedCatRes = await fetch(`${baseUrl}/api/categories/cement`, {
      method: 'DELETE',
      headers: authHeaders(),
    });
    assert.equal(delUsedCatRes.status, 409);
    const delUsedCatErr = (await delUsedCatRes.json()) as ApiErrorEnvelope;
    assert.equal(delUsedCatErr.error.code, 'CATEGORY_IN_USE');

    // C. Sales: Direct DELETE is prohibited (409 DELETION_PROHIBITED); Reversal restores stock and blocks duplicates
    const directDelSaleRes = await fetch(
      `${baseUrl}/api/sales/${saleBody.sale.id}`,
      {
        method: 'DELETE',
        headers: authHeaders(),
      }
    );
    assert.equal(directDelSaleRes.status, 409);
    const directDelSaleErr =
      (await directDelSaleRes.json()) as ApiErrorEnvelope;
    assert.equal(directDelSaleErr.error.code, 'DELETION_PROHIBITED');

    const revSaleRes = await fetch(
      `${baseUrl}/api/sales/${saleBody.sale.id}/reverse`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ reason: 'Order cancelled by contractor' }),
      }
    );
    assert.equal(revSaleRes.status, 200);
    const revSaleBody = (await revSaleRes.json()) as ReverseSaleResponse;
    assert.equal(revSaleBody.sale.isReversed, true);
    const cementAfterRev = revSaleBody.materials.find(
      (m) => m.id === 'mat_cement_opc'
    );
    assert.equal(cementAfterRev?.currentStock, 180);

    const dupRevSaleRes = await fetch(
      `${baseUrl}/api/sales/${saleBody.sale.id}/reverse`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ reason: 'Duplicate reversal' }),
      }
    );
    assert.equal(dupRevSaleRes.status, 409);
    const dupRevSaleErr = (await dupRevSaleRes.json()) as ApiErrorEnvelope;
    assert.equal(dupRevSaleErr.error.code, 'ALREADY_REVERSED');

    // D. Stock-In Reversal
    const stockInRes = await fetch(`${baseUrl}/api/stock-in`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        materialId: 'mat_cement_opc',
        quantityAdded: 20,
        unitPurchaseCost: 1200,
      }),
    });
    const stockInBody = (await stockInRes.json()) as CreateStockInResponse;

    const revStockInRes = await fetch(
      `${baseUrl}/api/stock-in/${stockInBody.stockIn.id}/reverse`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ reason: 'Incorrect delivery quantity entered' }),
      }
    );
    assert.equal(revStockInRes.status, 200);
    const revStockInBody =
      (await revStockInRes.json()) as ReverseStockInResponse;
    assert.equal(revStockInBody.stockIn.isReversed, true);
    assert.equal(revStockInBody.material.currentStock, 180);

    // E. Audit Reversal
    const auditRes = await fetch(`${baseUrl}/api/audits`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        items: [{ materialId: 'mat_cement_opc', physicalCount: 175 }],
        note: 'Yard count check',
      }),
    });
    const auditBody = (await auditRes.json()) as CreateAuditResponse;

    const revAuditRes = await fetch(
      `${baseUrl}/api/audits/${auditBody.audit.id}/reverse`,
      {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ reason: 'Audit entered on wrong item' }),
      }
    );
    assert.equal(revAuditRes.status, 200);
    const revAuditBody = (await revAuditRes.json()) as ReverseAuditResponse;
    assert.equal(revAuditBody.audit.isReversed, true);
    const cementAfterAuditRev = revAuditBody.materials.find(
      (m) => m.id === 'mat_cement_opc'
    );
    assert.equal(cementAfterAuditRev?.currentStock, 180);
  });
});

