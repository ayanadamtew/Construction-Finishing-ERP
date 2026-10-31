import assert from 'node:assert/strict';
import { Server } from 'node:http';
import { AddressInfo } from 'node:net';
import { afterEach, beforeEach, describe, it } from 'node:test';
import { createErpApiApp } from '../../server';
import { createInitialErpState } from '../domain/inventoryEngine';
import {
  ApiErrorEnvelope,
  CreateAuditResponse,
  CreateSaleResponse,
  CreateStockInResponse,
  ErpState,
  MaterialCategory,
  MaterialMutationResponse,
  MaterialUnit,
} from '../types/erp';

/**
 * Automated HTTP API Contract & Structured Error-Envelope Test Suite
 * Verifies all 6 endpoints and error codes defined in docs/API_CONTRACT.md
 * without mutating the persistent disk store.
 */
describe('HTTP API Contract & Error Envelopes (docs/API_CONTRACT.md)', () => {
  let server: Server;
  let baseUrl: string;
  let persistCallCount: number;

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
  });

  afterEach(async () => {
    if (server) {
      await new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
    }
  });

  it('1. GET /api/state returns 200 OK with initial materials, ledgers, and store summary', async () => {
    const res = await fetch(`${baseUrl}/api/state`);
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
        headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
        headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
    const stateRes = await fetch(`${baseUrl}/api/state`);
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
});
