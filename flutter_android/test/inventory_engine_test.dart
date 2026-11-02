import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construction_material_erp/core/constants/erp_constants.dart';
import 'package:construction_material_erp/core/errors/domain_error.dart';
import 'package:construction_material_erp/data/repositories/erp_repository.dart';
import 'package:construction_material_erp/domain/models/erp_models.dart';
import 'package:construction_material_erp/domain/services/auth_engine.dart';
import 'package:construction_material_erp/domain/services/inventory_engine.dart';
import 'package:construction_material_erp/l10n/erp_localizations.dart';
import 'package:construction_material_erp/main.dart';
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

    test('BR-001 Parity: allows updating unit on unused material and blocks unit update on used material', () {
      final seed = InventoryEngine.createSeedState();
      // mat-cement-derba is unused in seed state
      final updatedUnused = InventoryEngine.updateMaterialMetadata(
        seed,
        'mat-cement-derba',
        const UpdateMaterialInput(unit: MaterialUnit.kg),
      );
      expect(updatedUnused.material.unit, MaterialUnit.kg);

      // mat-cement-dangote is used in sale-seed-001 and stin-seed-001
      expect(
        () => InventoryEngine.updateMaterialMetadata(
          seed,
          'mat-cement-dangote',
          const UpdateMaterialInput(unit: MaterialUnit.kg),
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

  group('Production Data Cleanup & Sample Removal Tests', () {
    test('createProductionState initializes with 0 sample materials and transactions while keeping default categories', () {
      final prod = InventoryEngine.createProductionState();
      expect(prod.materials, isEmpty);
      expect(prod.sales, isEmpty);
      expect(prod.stockIns, isEmpty);
      expect(prod.audits, isEmpty);
      expect(prod.categories.length, 6);
      expect(prod.summary.totalMaterials, 0);
      expect(prod.summary.cumulativeSalesRevenue, 0);
    });

    test('cleanupSampleData removes known sample records while preserving genuine user materials and transactions', () {
      final seedWithSample = InventoryEngine.createSeedState();
      // Add a genuine user material and sale
      final registered = InventoryEngine.registerMaterial(
        seedWithSample,
        const RegisterMaterialInput(
          name: 'Genuine Customer Marble Slab',
          category: MaterialCategory.ceramics,
          specs: '120x60cm',
          unit: MaterialUnit.pcs,
          currentStock: 25,
          minStockLevel: 5,
          unitCost: 1400,
          defaultSellingPrice: 1850,
        ),
      );
      final withGenuineSale = InventoryEngine.recordSale(
        registered.state,
        RecordSaleInput(
          customerNote: 'Genuine Invoice #101',
          items: [
            SaleCartLineInput(
              materialId: registered.material.id,
              quantity: 5,
              unitSellingPrice: 1850,
            ),
          ],
        ),
      );

      final cleaned = InventoryEngine.cleanupSampleData(withGenuineSale.state);
      expect(cleaned.materials.length, 1);
      expect(cleaned.materials.first.id, registered.material.id);
      expect(cleaned.sales.length, 1);
      expect(cleaned.sales.first.customerNote, 'Genuine Invoice #101');
      expect(cleaned.stockIns, isEmpty);
    });
  });

  group('AuthEngine Pre-Registered Credentials & User Security Tests (FR-021 to FR-025)', () {
    test('hashes passwords with PBKDF2-SHA256 and authenticates valid username or email', () {
      final admin = AuthEngine.createDefaultAdminUser();
      expect(admin.passwordHash.startsWith('pbkdf2_sha256\$'), isTrue);
      expect(admin.passwordHash.contains('Admin@12345'), isFalse);

      final byUsername = AuthEngine.authenticateUser(
        users: [admin],
        usernameOrEmail: 'admin',
        password: r'Admin@12345',
      );
      expect(byUsername.username, 'admin');

      final byEfaEmail = AuthEngine.authenticateUser(
        users: [admin],
        usernameOrEmail: 'admin@efa.local',
        password: r'Admin@12345',
      );
      expect(byEfaEmail.id, admin.id);

      final byLegacyEmail = AuthEngine.authenticateUser(
        users: [admin],
        usernameOrEmail: 'admin@senayerp.local',
        password: r'Admin@12345',
      );
      expect(byLegacyEmail.id, admin.id);
    });

    test('rejects unknown username, wrong password, and deactivated user', () {
      final admin = AuthEngine.createDefaultAdminUser();
      final created = AuthEngine.createUserAccount(
        users: [admin],
        input: const CreateUserInput(
          username: 'cashier1',
          email: 'cashier1@efa.local',
          fullName: 'Kebede Cashier',
          role: UserRole.staff,
          password: 'StaffPassword1',
        ),
      );

      expect(
        () => AuthEngine.authenticateUser(
          users: created.users,
          usernameOrEmail: 'unknown_user',
          password: r'Admin@12345',
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'INVALID_CREDENTIALS',
          ),
        ),
      );

      expect(
        () => AuthEngine.authenticateUser(
          users: created.users,
          usernameOrEmail: 'admin',
          password: 'WrongPassword!',
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'INVALID_CREDENTIALS',
          ),
        ),
      );

      final deactivatedUsers = AuthEngine.toggleUserStatus(
        users: created.users,
        targetUserId: created.created.id,
        isActive: false,
        actorUserId: admin.id,
      );

      expect(
        () => AuthEngine.authenticateUser(
          users: deactivatedUsers,
          usernameOrEmail: 'cashier1',
          password: 'StaffPassword1',
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_DEACTIVATED',
          ),
        ),
      );
    });

    test('BR-010: prevents deactivating or deleting the last active administrator or self', () {
      final admin = AuthEngine.createDefaultAdminUser();
      expect(
        () => AuthEngine.toggleUserStatus(
          users: [admin],
          targetUserId: admin.id,
          isActive: false,
          actorUserId: 'USR-OTHER',
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'LAST_ADMIN_PROTECTION',
          ),
        ),
      );

      expect(
        () => AuthEngine.deleteUserAccount(
          users: [admin],
          targetUserId: admin.id,
          actorUserId: admin.id,
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'SELF_MODIFICATION_FORBIDDEN',
          ),
        ),
      );
    });
  });

  group('Safe Delete, Archive, Category & Reversal Domain Tests (FR-026 to FR-030)', () {
    test('BR-011: deletes unused material permanently, but blocks deleting used material', () {
      final seed = InventoryEngine.createSeedState();
      // mat-cement-derba has no sales, stock-ins, or audits in seed state
      final deleted = InventoryEngine.deleteMaterial(seed, 'mat-cement-derba');
      expect(deleted.deletedMaterial.id, 'mat-cement-derba');
      expect(
        deleted.state.materials.any((m) => m.id == 'mat-cement-derba'),
        isFalse,
      );

      // mat-cement-dangote is used in sale-seed-001 and stin-seed-001
      expect(
        () => InventoryEngine.deleteMaterial(seed, 'mat-cement-dangote'),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'MATERIAL_IN_USE',
          ),
        ),
      );
    });

    test('FR-027: archives and restores used material and blocks selling archived material', () {
      final seed = InventoryEngine.createSeedState();
      final archivedRes = InventoryEngine.setMaterialArchivedStatus(
        seed,
        'mat-cement-dangote',
        isArchived: true,
        actorUsername: 'admin',
      );
      expect(archivedRes.material.isArchived, isTrue);
      expect(
        archivedRes.state.summary.totalMaterials,
        seed.summary.totalMaterials - 1,
      );

      expect(
        () => InventoryEngine.recordSale(
          archivedRes.state,
          const RecordSaleInput(
            items: [
              SaleCartLineInput(
                materialId: 'mat-cement-dangote',
                quantity: 5,
                unitSellingPrice: 1350,
              ),
            ],
          ),
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'MATERIAL_ARCHIVED',
          ),
        ),
      );

      final restoredRes = InventoryEngine.setMaterialArchivedStatus(
        archivedRes.state,
        'mat-cement-dangote',
        isArchived: false,
        actorUsername: 'admin',
      );
      expect(restoredRes.material.isArchived, isFalse);
      expect(
        restoredRes.state.summary.totalMaterials,
        seed.summary.totalMaterials,
      );
    });

    test('FR-028 & BR-012: creates custom category, deletes unused category, and blocks deleting category in use', () {
      final seed = InventoryEngine.createSeedState();
      final createdCat = InventoryEngine.createCategory(
        seed,
        const CreateCategoryInput(
          code: 'sanitary',
          name: 'Sanitary Ware & Fittings',
        ),
        actorUsername: 'admin',
      );
      expect(
        createdCat.state.categories.any((c) => c.code == 'sanitary'),
        isTrue,
      );

      // Register material in sanitary category
      final withMat = InventoryEngine.registerMaterial(
        createdCat.state,
        const RegisterMaterialInput(
          name: 'Ceramic Wash Basin',
          category: MaterialCategory.other,
          categoryCode: 'sanitary',
          unit: MaterialUnit.pcs,
          currentStock: 10,
          minStockLevel: 2,
          unitCost: 2200,
          defaultSellingPrice: 2800,
        ),
      );

      // Cannot delete category while material uses it
      expect(
        () => InventoryEngine.deleteCategory(withMat.state, 'sanitary'),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'CATEGORY_IN_USE',
          ),
        ),
      );

      // Delete the unused material first, then delete the custom category
      final afterMatDelete =
          InventoryEngine.deleteMaterial(withMat.state, withMat.material.id);
      final afterCatDelete =
          InventoryEngine.deleteCategory(afterMatDelete.state, 'sanitary');
      expect(
        afterCatDelete.state.categories.any((c) => c.code == 'sanitary'),
        isFalse,
      );
    });

    test('FR-029 & BR-013: reverses a sale transaction, restores stock, and blocks duplicate reversal', () {
      final seed = InventoryEngine.createSeedState();
      // sale-seed-001 sold 20 bags of mat-cement-dangote (currentStock 240) and 15 bars of mat-rebar-12mm (currentStock 180)
      final reversed = InventoryEngine.reverseSaleTransaction(
        seed,
        'sale-seed-001',
        reason: 'Customer returned unopened bags to warehouse',
        actorUsername: 'admin',
      );

      expect(reversed.sale.isReversed, isTrue);
      expect(reversed.sale.reversedBy, 'admin');
      final dangote = reversed.state.materials
          .firstWhere((m) => m.id == 'mat-cement-dangote');
      final rebar12 = reversed.state.materials
          .firstWhere((m) => m.id == 'mat-rebar-12mm');
      expect(dangote.currentStock, 260);
      expect(rebar12.currentStock, 195);
      expect(reversed.state.summary.cumulativeSalesRevenue, 0);

      // Duplicate reversal blocked
      expect(
        () => InventoryEngine.reverseSaleTransaction(
          reversed.state,
          'sale-seed-001',
          reason: 'Second attempt',
          actorUsername: 'admin',
        ),
        throwsA(
          isA<AppDomainError>().having(
            (e) => e.code,
            'code',
            'ALREADY_REVERSED',
          ),
        ),
      );
    });

    test('FR-030 & BR-014: reverses Stock-In and Stock Audit records while guarding against negative stock', () {
      final seed = InventoryEngine.createSeedState();
      final stockInRes = InventoryEngine.recordStockIn(
        seed,
        const RecordStockInInput(
          materialId: 'mat-rebar-16mm', // 32 @ 1980
          quantityAdded: 68, // -> 100 @ 2061.60
          unitPurchaseCost: 2100,
        ),
      );

      final reversedStin = InventoryEngine.reverseStockInRecord(
        stockInRes.state,
        stockInRes.stockIn.id,
        reason: 'Wrong delivery waybill entered',
        actorUsername: 'admin',
      );
      final rebar16 = reversedStin.state.materials
          .firstWhere((m) => m.id == 'mat-rebar-16mm');
      expect(rebar16.currentStock, 32);
      expect(rebar16.unitCost, 1980);

      // Stock audit reversal
      final auditRes = InventoryEngine.recordStockAudit(
        seed,
        const RecordStockAuditInput(
          adjustments: [
            AuditAdjustmentInput(
              materialId: 'mat-cement-derba', // 45 -> 40 (-5 variance)
              physicalCount: 40,
            ),
          ],
          auditNote: 'Floor count',
        ),
      );
      final reversedAudit = InventoryEngine.reverseStockAuditRecord(
        auditRes.state,
        auditRes.audit.id,
        reason: 'Miscounted pallets in section B',
        actorUsername: 'admin',
      );
      final derba = reversedAudit.state.materials
          .firstWhere((m) => m.id == 'mat-cement-derba');
      expect(derba.currentStock, 45);
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

  group('ErpController State, EFA Metadata & Trilingual Draft Preservation', () {
    test('EFA application metadata and developer information match exact project specifications', () {
      expect(ErpAppInfo.appName, 'EFA');
      expect(ErpAppInfo.developerName, 'Ayana Damtew');
      expect(ErpAppInfo.developerPhone, '+251973395537');
      expect(ErpAppInfo.appVersion, '1.0.0');
      expect(ErpAppInfo.buildNumber, '1');
      expect(ErpAppInfo.appDescription, isNotEmpty);

      for (final lang in AppLanguage.values) {
        final i18n = ErpLocalizations(lang);
        expect(i18n.t('appTitle'), 'EFA');
        expect(i18n.t('aboutEfaTitle').contains('EFA'), isTrue);
      }
    });

    test('FAIL-003: switching languages preserves draft POS cart and audit counts', () {
      final repo = ErpRepository(seedDemoData: true);
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

    test('supports 5-tab navigation helpers, Stock-In deep link, and POS cart quantity/clear helpers', () {
      final repo = ErpRepository(seedDemoData: true);
      final controller = ErpController(repo);

      controller.openInventorySubTab(1);
      expect(controller.state.activeTabIndex, 3);
      expect(controller.state.inventorySubTab, 1);

      controller.openStockInForMaterial('mat-rebar-16mm');
      expect(controller.state.activeTabIndex, 3);
      expect(controller.state.inventorySubTab, 0);
      expect(controller.state.selectedStockInMaterialId, 'mat-rebar-16mm');

      controller.addOrUpdateCartItem(
        const SaleCartLineInput(
          materialId: 'mat-rebar-12mm',
          quantity: 4,
          unitSellingPrice: 980,
        ),
      );
      controller.setCartItemQuantity('mat-rebar-12mm', 7);
      expect(controller.state.draftCart.first.quantity, 7);

      controller.clearDraftCart();
      expect(controller.state.draftCart, isEmpty);

      controller.openMoreSubTab(2);
      expect(controller.state.activeTabIndex, 4);
      expect(controller.state.moreSubTab, 2);

      for (final lang in AppLanguage.values) {
        final i18n = ErpLocalizations(lang);
        expect(i18n.t('navDashboard').isNotEmpty, isTrue);
        expect(i18n.t('navMaterials').isNotEmpty, isTrue);
        expect(i18n.t('navSales').isNotEmpty, isTrue);
        expect(i18n.t('navInventory').isNotEmpty, isTrue);
        expect(i18n.t('navMore').isNotEmpty, isTrue);
      }
    });
  });

  group('EFA UI Widget & Bottom Navigation Overflow Tests (320dp, 360dp, 412dp)', () {
    testWidgets(
      'renders EFA login, bottom navigation (including Inventory), and About EFA without pixel overflow across screen widths and languages',
      (WidgetTester tester) async {
        final repo = ErpRepository();
        final controller = ErpController(repo);
        await controller.login('admin', r'Admin@12345');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              erpRepositoryProvider.overrideWithValue(repo),
              erpControllerProvider.overrideWith((ref) => controller),
            ],
            child: const EfaErpApp(),
          ),
        );
        await tester.pumpAndSettle();

        for (final width in <double>[320, 360, 412]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          for (final lang in AppLanguage.values) {
            controller.setLanguage(lang);
            await tester.pumpAndSettle();

            final i18n = ErpLocalizations(lang);
            expect(find.text(i18n.t('navDashboard')), findsWidgets);
            expect(find.text(i18n.t('navMaterials')), findsWidgets);
            expect(find.text(i18n.t('navSales')), findsWidgets);
            expect(find.text(i18n.t('navInventory')), findsWidgets);
            expect(find.text(i18n.t('navMore')), findsWidgets);
            expect(tester.takeException(), isNull);
          }
        }

        // Reset to English and verify Settings -> About EFA section
        controller.setLanguage(AppLanguage.en);
        controller.openMoreSubTab(2);
        await tester.pumpAndSettle();

        expect(find.text('About EFA'), findsOneWidget);
        expect(find.text('Ayana Damtew'), findsOneWidget);
        expect(find.text('+251973395537'), findsOneWidget);
        expect(find.text('1.0.0'), findsOneWidget);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}

