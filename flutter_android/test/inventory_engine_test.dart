import 'package:flutter_test/flutter_test.dart';
import 'package:construction_material_erp/core/constants/erp_constants.dart';
import 'package:construction_material_erp/core/errors/domain_error.dart';
import 'package:construction_material_erp/data/repositories/erp_repository.dart';
import 'package:construction_material_erp/domain/models/erp_models.dart';
import 'package:construction_material_erp/domain/services/inventory_engine.dart';
import 'package:construction_material_erp/l10n/erp_localizations.dart';
import 'package:construction_material_erp/presentation/providers/erp_providers.dart';

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

  group('ErpApiClient & JSON Contract Parity Tests (docs/API_CONTRACT.md)', () {
    test('deserializes root-level GET /api/state server payload accurately', () {
      final serverStateJson = <String, dynamic>{
        'materials': [
          {
            'id': 'mat_1',
            'name': 'Deformed Rebar 12mm',
            'category': 'rebar',
            'specs': 'Ø12mm • Grade 60 • 12m length',
            'unit': 'bars',
            'currentStock': 200,
            'minStockLevel': 30,
            'unitCost': 850.0,
            'defaultSellingPrice': 980.0,
            'createdAt': '2026-10-30T08:00:00.000Z',
            'updatedAt': '2026-10-30T08:00:00.000Z',
          }
        ],
        'sales': [
          {
            'id': 'sale_1',
            'createdAt': '2026-10-31T10:00:00.000Z',
            'customerNote': 'Site delivery - Bole project',
            'items': [
              {
                'materialId': 'mat_1',
                'materialName': 'Deformed Rebar 12mm',
                'unit': 'bars',
                'quantity': 20,
                'unitSellingPrice': 980.0,
                'unitCostSnapshot': 850.0,
                'lineTotal': 19600.0,
                'lineProfit': 2600.0,
              }
            ],
            'totalRevenue': 19600.0,
            'totalProfit': 2600.0,
          }
        ],
        'stockIns': [
          {
            'id': 'stkin_1',
            'materialId': 'mat_1',
            'materialName': 'Deformed Rebar 12mm',
            'unit': 'bars',
            'quantityAdded': 50,
            'unitPurchaseCost': 860.0,
            'totalCost': 43000.0,
            'previousStock': 180,
            'newStock': 230,
            'supplierNote': 'Batch #12',
            'createdAt': '2026-10-31T10:05:00.000Z',
          }
        ],
        'audits': [
          {
            'id': 'audit_1',
            'createdAt': '2026-10-31T10:10:00.000Z',
            'note': 'Weekly yard count',
            'adjustments': [
              {
                'materialId': 'mat_1',
                'materialName': 'Deformed Rebar 12mm',
                'unit': 'bars',
                'expectedStock': 230,
                'physicalCount': 228,
                'variance': -2,
                'unitCostSnapshot': 852.17,
              }
            ],
          }
        ],
        'summary': {
          'totalRevenue': 19600.0,
          'totalProfit': 2600.0,
          'inventoryCostValue': 170000.0,
          'inventoryRetailValue': 196000.0,
          'lowStockCount': 0,
        },
      };

      final material = MaterialItem.fromJson(
          (serverStateJson['materials'] as List).first as Map<String, dynamic>);
      final sale = SaleTransaction.fromJson(
          (serverStateJson['sales'] as List).first as Map<String, dynamic>);
      final stockIn = StockInRecord.fromJson(
          (serverStateJson['stockIns'] as List).first as Map<String, dynamic>);
      final audit = StockAuditRecord.fromJson(
          (serverStateJson['audits'] as List).first as Map<String, dynamic>);
      final summary = StoreSummary.fromJson(
        serverStateJson['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: 1,
        fallbackTotalSalesCount: 1,
      );

      expect(material.id, 'mat_1');
      expect(sale.totalAmount, 19600.0);
      expect(sale.totalCost, 17000.0);
      expect(stockIn.totalPurchaseCost, 43000.0);
      expect(audit.auditNote, 'Weekly yard count');
      expect(summary.totalStockValuationCost, 170000.0);
      expect(summary.cumulativeSalesRevenue, 19600.0);
    });
  });

  group('ErpController State & Trilingual Draft Preservation (FAIL-003)', () {
    test('FAIL-003: switching languages preserves draft POS cart and audit counts', () {
      final repo = ErpRepository();
      final controller = ErpController(repo);

      controller.addOrUpdateCartItem(
        const SaleCartLineInput(
          materialId: 'mat-rebar-12mm',
          quantity: 10,
          unitSellingPrice: 980,
        ),
      );
      controller.updateDraftAuditCount('mat-cement-derba', 44);

      controller.setLanguage(AppLanguage.am);
      expect(controller.state.language, AppLanguage.am);
      expect(controller.state.draftCart.length, 1);
      expect(controller.state.draftCart.first.quantity, 10);
      expect(controller.state.draftAuditCounts['mat-cement-derba'], 44);
      expect(
        controller.state.i18n.t('recentSalesSection'),
        'የቅርብ ጊዜ የሽያጭ ደረሰኞች',
      );

      controller.setLanguage(AppLanguage.om);
      expect(controller.state.language, AppLanguage.om);
      expect(controller.state.draftCart.first.quantity, 10);
      expect(
        controller.state.i18n.t('recentSalesSection'),
        'Nagaheewwan Gurgurtaa Dhihoo',
      );
    });

    test('toggles companion server write-through sync mode accurately', () {
      final repo = ErpRepository();
      final controller = ErpController(repo);

      expect(controller.state.companionSyncEnabled, false);
      expect(repo.syncWithCompanionServer, false);

      controller.toggleCompanionSync(true);
      expect(controller.state.companionSyncEnabled, true);
      expect(repo.syncWithCompanionServer, true);

      controller.toggleCompanionSync(false);
      expect(controller.state.companionSyncEnabled, false);
      expect(repo.syncWithCompanionServer, false);
    });
  });
}
