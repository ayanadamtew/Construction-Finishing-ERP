import 'package:flutter_test/flutter_test.dart';
import 'package:senay_construction_erp/core/constants/erp_constants.dart';
import 'package:senay_construction_erp/core/errors/domain_error.dart';
import 'package:senay_construction_erp/domain/models/erp_models.dart';
import 'package:senay_construction_erp/domain/services/inventory_engine.dart';

void main() {
  group('InventoryEngine Domain Tests (BR-001 to BR-008)', () {
    test('AC-001: registers a SKU-free material and updates valuation', () {
      final seed = InventoryEngine.createSeedState(
        nowIso: '2026-03-31T08:00:00.000Z',
      );
      final res = InventoryEngine.registerMaterial(
        seed,
        const RegisterMaterialInput(
          name: 'PPR Hot Water Pipe PN20 25mm',
          category: MaterialCategory.hardware,
          specs: '25mm x 4m Bar',
          unit: MaterialUnit.pcs,
          currentStock: 100,
          minStockLevel: 20,
          unitCost: 310,
          defaultSellingPrice: 390,
        ),
      );

      expect(res.material.name, 'PPR Hot Water Pipe PN20 25mm');
      expect(res.state.materials.length, seed.materials.length + 1);
    });

    test('BR-001 / BR-007: blocks direct stock or cost modification in metadata edit', () {
      final seed = InventoryEngine.createSeedState();
      expect(
        () => InventoryEngine.updateMaterialMetadata(
          seed,
          'mat-rebar-12mm',
          const UpdateMaterialInput(
            name: 'Updated Name',
            rawAttemptedFields: {'currentStock': 999},
          ),
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'IMMUTABLE_FIELD_VIOLATION',
          ),
        ),
      );
    });

    test('AC-002 & BR-002: blocks overselling with INSUFFICIENT_STOCK', () {
      final seed = InventoryEngine.createSeedState();
      expect(
        () => InventoryEngine.recordSale(
          seed,
          const RecordSaleInput(
            items: [
              SaleCartLineInput(
                materialId: 'mat-rebar-16mm',
                quantity: 50, // Only 32 available
                unitSellingPrice: 2250,
              ),
            ],
          ),
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'INSUFFICIENT_STOCK',
          ),
        ),
      );
    });

    test('AC-004 & BR-006: recalculates weighted-average unit cost on Stock-In', () {
      final seed = InventoryEngine.createSeedState();
      final res = InventoryEngine.recordStockIn(
        seed,
        const RecordStockInInput(
          materialId: 'mat-rebar-16mm', // 32 bars @ 1980 ETB
          quantityAdded: 68, // +68 bars @ 2100 ETB => 100 bars total
          unitPurchaseCost: 2100,
          supplierNote: 'New Steel Mill Batch',
        ),
      );

      // ((32 * 1980) + (68 * 2100)) / 100 = (63360 + 142800) / 100 = 2061.60 ETB
      expect(res.material.currentStock, 100);
      expect(res.material.unitCost, 2061.60);
    });

    test('AC-005: records physical ground-stock audit variance accurately', () {
      final seed = InventoryEngine.createSeedState();
      final res = InventoryEngine.recordStockAudit(
        seed,
        const RecordStockAuditInput(
          adjustments: [
            AuditAdjustmentInput(
              materialId: 'mat-cement-derba', // Expected 45 bags
              physicalCount: 42, // -3 variance (damaged bags)
            ),
          ],
          auditNote: 'Monthly Warehouse Floor Count',
        ),
      );

      expect(res.audit.adjustments.first.variance, -3);
      final updatedDerba = res.state.materials
          .firstWhere((m) => m.id == 'mat-cement-derba');
      expect(updatedDerba.currentStock, 42);
    });
  });
}
