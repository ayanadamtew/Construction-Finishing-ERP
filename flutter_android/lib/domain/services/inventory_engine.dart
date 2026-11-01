import 'dart:math';
import '../../core/constants/erp_constants.dart';
import '../../core/errors/domain_error.dart';
import '../models/erp_models.dart';

final _random = Random();

String _shortId() {
  const hex = '0123456789abcdef';
  return List.generate(8, (_) => hex[_random.nextInt(16)]).join();
}

/// Pure domain engine enforcing all business rules (`BR-001` through `BR-014`)
/// and acceptance criteria (`AC-001` through `AC-010`).
class InventoryEngine {
  static List<CategoryRecord> createDefaultCategories({String? nowIso}) {
    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    return <CategoryRecord>[
      CategoryRecord(
        id: 'cat-rebar',
        code: 'rebar',
        name: 'Reinforcement Steel (Rebar)',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
      CategoryRecord(
        id: 'cat-cement',
        code: 'cement',
        name: 'Portland & PPC Cement',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
      CategoryRecord(
        id: 'cat-tiles',
        code: 'tiles',
        name: 'Ceramic & Porcelain Tiles',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
      CategoryRecord(
        id: 'cat-paint',
        code: 'paint',
        name: 'Architectural Paints & Primers',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
      CategoryRecord(
        id: 'cat-hardware',
        code: 'hardware',
        name: 'General Finishing Hardware',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
      CategoryRecord(
        id: 'cat-other',
        code: 'other',
        name: 'Other Finishing Materials',
        isSystem: true,
        createdAt: timestamp,
        createdBy: 'system',
      ),
    ];
  }

  static StoreSummary calculateSummary({
    required List<MaterialItem> materials,
    required List<SaleTransaction> sales,
    String? referenceDateIso,
  }) {
    final todayPrefix =
        (referenceDateIso ?? DateTime.now().toUtc().toIso8601String())
            .substring(0, 10);

    final activeMaterials = materials.where((m) => !m.isArchived).toList();
    final activeSales = sales.where((s) => !s.isReversed).toList();

    int lowStockCount = 0;
    double totalStockValuationCost = 0;
    double totalStockValuationRetail = 0;

    for (final m in activeMaterials) {
      if (m.currentStock <= m.minStockLevel) {
        lowStockCount += 1;
      }
      totalStockValuationCost += m.currentStock * m.unitCost;
      totalStockValuationRetail += m.currentStock * m.defaultSellingPrice;
    }

    double todaySalesRevenue = 0;
    double todaySalesProfit = 0;
    double cumulativeSalesRevenue = 0;
    double cumulativeSalesProfit = 0;

    for (final sale in activeSales) {
      cumulativeSalesRevenue += sale.totalAmount;
      cumulativeSalesProfit += sale.totalProfit;
      if (sale.createdAt.startsWith(todayPrefix)) {
        todaySalesRevenue += sale.totalAmount;
        todaySalesProfit += sale.totalProfit;
      }
    }

    return StoreSummary(
      totalMaterials: activeMaterials.length,
      lowStockCount: lowStockCount,
      totalStockValuationCost: round2(totalStockValuationCost),
      totalStockValuationRetail: round2(totalStockValuationRetail),
      todaySalesRevenue: round2(todaySalesRevenue),
      todaySalesProfit: round2(todaySalesProfit),
      cumulativeSalesRevenue: round2(cumulativeSalesRevenue),
      cumulativeSalesProfit: round2(cumulativeSalesProfit),
      totalSalesCount: activeSales.length,
    );
  }

  static ErpState createSeedState({String? nowIso}) {
    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final categories = createDefaultCategories(nowIso: timestamp);
    final materials = <MaterialItem>[
      MaterialItem(
        id: 'mat-rebar-12mm',
        name: 'Deformed Steel Rebar 12mm',
        category: MaterialCategory.rebar,
        specs: '12mm x 12m • Grade 60',
        unit: MaterialUnit.bars,
        currentStock: 180,
        minStockLevel: 50,
        unitCost: 1120,
        defaultSellingPrice: 1290,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-rebar-16mm',
        name: 'Deformed Steel Rebar 16mm',
        category: MaterialCategory.rebar,
        specs: '16mm x 12m • Grade 60',
        unit: MaterialUnit.bars,
        currentStock: 32,
        minStockLevel: 40,
        unitCost: 1980,
        defaultSellingPrice: 2250,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-cement-dangote',
        name: 'Dangote OPC Cement 42.5R',
        category: MaterialCategory.cement,
        specs: '50kg Sack • Ordinary Portland',
        unit: MaterialUnit.bags,
        currentStock: 240,
        minStockLevel: 80,
        unitCost: 1180,
        defaultSellingPrice: 1350,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-cement-derba',
        name: 'Derba PPC Cement 32.5N',
        category: MaterialCategory.cement,
        specs: '50kg Sack • Pozzolana Portland',
        unit: MaterialUnit.bags,
        currentStock: 45,
        minStockLevel: 60,
        unitCost: 1090,
        defaultSellingPrice: 1240,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-tiles-porcelain-60',
        name: 'Spanish Glazed Porcelain Floor Tile',
        category: MaterialCategory.tiles,
        specs: '60x60cm • 1.44 sqm/box • Ivory Matte',
        unit: MaterialUnit.boxes,
        currentStock: 95,
        minStockLevel: 25,
        unitCost: 1450,
        defaultSellingPrice: 1780,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-paint-kadisco-white',
        name: 'Kadisco Super Acrylic Emulsion Paint',
        category: MaterialCategory.paint,
        specs: '20L Bucket • Brilliant White',
        unit: MaterialUnit.buckets,
        currentStock: 14,
        minStockLevel: 15,
        unitCost: 3400,
        defaultSellingPrice: 3950,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      MaterialItem(
        id: 'mat-hardware-binding-wire',
        name: 'Galvanized Annealed Binding Wire',
        category: MaterialCategory.hardware,
        specs: '1.2mm Gauge • Roll',
        unit: MaterialUnit.kg,
        currentStock: 110,
        minStockLevel: 30,
        unitCost: 165,
        defaultSellingPrice: 210,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];

    final sales = <SaleTransaction>[
      SaleTransaction(
        id: 'sale-seed-001',
        items: const [
          SaleLineItem(
            id: 'sli-seed-001',
            materialId: 'mat-cement-dangote',
            materialName: 'Dangote OPC Cement 42.5R',
            unit: MaterialUnit.bags,
            quantity: 20,
            unitSellingPrice: 1350,
            unitCostSnapshot: 1180,
            lineTotal: 27000,
            lineProfit: 3400,
          ),
          SaleLineItem(
            id: 'sli-seed-002',
            materialId: 'mat-rebar-12mm',
            materialName: 'Deformed Steel Rebar 12mm',
            unit: MaterialUnit.bars,
            quantity: 15,
            unitSellingPrice: 1290,
            unitCostSnapshot: 1120,
            lineTotal: 19350,
            lineProfit: 2550,
          ),
        ],
        totalAmount: 46350,
        totalCost: 40400,
        totalProfit: 5950,
        customerNote: 'Bole Site Contractor - Ato Dawit',
        createdAt: timestamp,
      ),
    ];

    final stockIns = <StockInRecord>[
      StockInRecord(
        id: 'stin-seed-001',
        materialId: 'mat-cement-dangote',
        materialName: 'Dangote OPC Cement 42.5R',
        unit: MaterialUnit.bags,
        quantityAdded: 100,
        unitPurchaseCost: 1180,
        totalPurchaseCost: 118000,
        previousStock: 140,
        newStock: 240,
        previousUnitCost: 1180,
        newUnitCost: 1180,
        supplierNote: 'Mugher / Dangote Distributor Truck #AA-41920',
        createdAt: timestamp,
      ),
    ];

    const audits = <StockAuditRecord>[];

    return ErpState(
      materials: materials,
      sales: sales,
      stockIns: stockIns,
      audits: audits,
      categories: categories,
      summary: calculateSummary(
        materials: materials,
        sales: sales,
        referenceDateIso: timestamp,
      ),
    );
  }

  /// Registers a new SKU-free material (`FR-001`–`FR-005`, `AC-001`).
  static ({ErpState state, MaterialItem material}) registerMaterial(
    ErpState state,
    RegisterMaterialInput input, {
    String? nowIso,
  }) {
    final name = input.name.trim();
    if (name.isEmpty || name.length > 120) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message:
            'Material name is required and must be between 1 and 120 characters.',
        status: 400,
      );
    }

    final specs = input.specs.trim();
    if (specs.length > 120) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Material specs cannot exceed 120 characters.',
        status: 400,
      );
    }

    if (input.currentStock.isNaN || input.currentStock < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Opening stock must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    if (input.minStockLevel.isNaN || input.minStockLevel < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message:
            'Minimum stock alert level must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    if (input.unitCost.isNaN || input.unitCost < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Initial unit cost (ETB) must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    if (input.defaultSellingPrice.isNaN || input.defaultSellingPrice < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message:
            'Default selling price (ETB) must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final catCode =
        (input.categoryCode != null && input.categoryCode!.trim().isNotEmpty)
            ? input.categoryCode!.trim().toLowerCase()
            : input.category.code;

    final material = MaterialItem(
      id: 'mat-${_shortId()}',
      name: name,
      category: MaterialCategory.fromCode(catCode),
      categoryCode: catCode,
      specs: specs,
      unit: input.unit,
      currentStock: round2(input.currentStock),
      minStockLevel: round2(input.minStockLevel),
      unitCost: round2(input.unitCost),
      defaultSellingPrice: round2(input.defaultSellingPrice),
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final materials = [material, ...state.materials];
    return (
      material: material,
      state: ErpState(
        materials: materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Updates mutable material metadata only (`BR-001`, `BR-007`).
  static ({ErpState state, MaterialItem material}) updateMaterialMetadata(
    ErpState state,
    String materialId,
    UpdateMaterialInput input, {
    String? nowIso,
  }) {
    final raw = input.rawAttemptedFields;
    if (raw != null) {
      if (raw.containsKey('currentStock') ||
          raw.containsKey('unitCost') ||
          raw.containsKey('unit')) {
        throw const AppDomainError(
          code: 'IMMUTABLE_FIELD_VIOLATION',
          message:
              'Direct modification of currentStock, unitCost, or unit is forbidden by ledger rules (BR-001 / BR-007). Use Stock-In or Stock Audit instead.',
          status: 400,
        );
      }
    }

    final index = state.materials.indexWhere((m) => m.id == materialId);
    if (index == -1) {
      throw AppDomainError(
        code: 'MATERIAL_NOT_FOUND',
        message: 'Material with id "$materialId" was not found.',
        status: 404,
      );
    }

    final existing = state.materials[index];
    final nextName = input.name != null ? input.name!.trim() : existing.name;
    if (nextName.isEmpty || nextName.length > 120) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Material name must be between 1 and 120 characters.',
        status: 400,
      );
    }

    final nextSpecs =
        input.specs != null ? input.specs!.trim() : existing.specs;
    if (nextSpecs.length > 120) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Material specs cannot exceed 120 characters.',
        status: 400,
      );
    }

    final nextMinStock = input.minStockLevel ?? existing.minStockLevel;
    if (nextMinStock.isNaN || nextMinStock < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Minimum stock alert level must be >= 0.',
        status: 400,
      );
    }

    final nextSellingPrice =
        input.defaultSellingPrice ?? existing.defaultSellingPrice;
    if (nextSellingPrice.isNaN || nextSellingPrice < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Default selling price (ETB) must be >= 0.',
        status: 400,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final nextCategoryCode = input.categoryCode != null
        ? input.categoryCode!.trim().toLowerCase()
        : (input.category != null
            ? input.category!.code
            : existing.effectiveCategoryCode);

    final updated = existing.copyWith(
      name: nextName,
      category: input.category ?? MaterialCategory.fromCode(nextCategoryCode),
      categoryCode: nextCategoryCode,
      specs: nextSpecs,
      minStockLevel: round2(nextMinStock),
      defaultSellingPrice: round2(nextSellingPrice),
      updatedAt: timestamp,
    );

    final materials = [...state.materials];
    materials[index] = updated;

    return (
      material: updated,
      state: ErpState(
        materials: materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Checks whether a material is referenced by any sale, stock-in, or audit record (`BR-011`).
  static bool isMaterialUsed(ErpState state, String materialId) {
    final usedInSales = state.sales.any(
      (s) => s.items.any((line) => line.materialId == materialId),
    );
    if (usedInSales) return true;

    final usedInStockIns =
        state.stockIns.any((stin) => stin.materialId == materialId);
    if (usedInStockIns) return true;

    final usedInAudits = state.audits.any(
      (aud) => aud.adjustments.any((adj) => adj.materialId == materialId),
    );
    return usedInAudits;
  }

  /// Permanently deletes an unused material; rejects deletion if historical records exist (`FR-026`, `BR-011`).
  static ({ErpState state, MaterialItem deletedMaterial}) deleteMaterial(
    ErpState state,
    String materialId, {
    String? nowIso,
  }) {
    final idx = state.materials.indexWhere((m) => m.id == materialId);
    if (idx == -1) {
      throw AppDomainError(
        code: 'MATERIAL_NOT_FOUND',
        message: 'Material "$materialId" was not found.',
        status: 404,
      );
    }

    final material = state.materials[idx];
    if (isMaterialUsed(state, materialId)) {
      throw AppDomainError(
        code: 'MATERIAL_IN_USE',
        message:
            'Cannot permanently delete "${material.name}" because it has historical sales, stock-in, or audit records. Please Archive it instead.',
        status: 409,
        details: {'materialId': materialId, 'materialName': material.name},
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final materials =
        state.materials.where((m) => m.id != materialId).toList();

    return (
      deletedMaterial: material,
      state: ErpState(
        materials: materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Archives or restores a material (`FR-027`, `BR-011`).
  static ({ErpState state, MaterialItem material}) setMaterialArchivedStatus(
    ErpState state,
    String materialId, {
    required bool isArchived,
    required String actorUsername,
    String? nowIso,
  }) {
    final idx = state.materials.indexWhere((m) => m.id == materialId);
    if (idx == -1) {
      throw AppDomainError(
        code: 'MATERIAL_NOT_FOUND',
        message: 'Material "$materialId" was not found.',
        status: 404,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final existing = state.materials[idx];
    final updated = existing.copyWith(
      isArchived: isArchived,
      archivedAt: isArchived ? timestamp : null,
      archivedBy: isArchived ? actorUsername : null,
      clearArchiveMetadata: !isArchived,
      updatedAt: timestamp,
    );

    final materials = [...state.materials];
    materials[idx] = updated;

    return (
      material: updated,
      state: ErpState(
        materials: materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Creates a custom material category (`FR-028`).
  static ({ErpState state, CategoryRecord category}) createCategory(
    ErpState state,
    CreateCategoryInput input, {
    required String actorUsername,
    String? nowIso,
  }) {
    final rawCode = input.code
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final name = input.name.trim();

    if (rawCode.length < 2 || rawCode.length > 32) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Category code must be between 2 and 32 characters.',
        status: 400,
      );
    }
    if (name.isEmpty || name.length > 60) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Category name is required (max 60 characters).',
        status: 400,
      );
    }

    final existingCats = state.categories.isNotEmpty
        ? state.categories
        : createDefaultCategories(nowIso: nowIso);

    if (existingCats.any((c) => c.code.toLowerCase() == rawCode)) {
      throw AppDomainError(
        code: 'DUPLICATE_CATEGORY',
        message: 'Category code "$rawCode" already exists.',
        status: 409,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final created = CategoryRecord(
      id: 'cat-$rawCode-${_shortId().substring(0, 4)}',
      code: rawCode,
      name: name,
      isSystem: false,
      createdAt: timestamp,
      createdBy: actorUsername,
    );

    final categories = [...existingCats, created];
    return (
      category: created,
      state: ErpState(
        materials: state.materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: categories,
        summary: state.summary,
      ),
    );
  }

  /// Deletes a category only when it is not a system category and no materials use it (`FR-028`, `BR-012`).
  static ({ErpState state, CategoryRecord deletedCategory}) deleteCategory(
    ErpState state,
    String categoryIdOrCode,
  ) {
    final existingCats = state.categories.isNotEmpty
        ? state.categories
        : createDefaultCategories();

    final idx = existingCats.indexWhere(
      (c) => c.id == categoryIdOrCode || c.code == categoryIdOrCode,
    );
    if (idx == -1) {
      throw AppDomainError(
        code: 'CATEGORY_NOT_FOUND',
        message: 'Category "$categoryIdOrCode" was not found.',
        status: 404,
      );
    }

    final target = existingCats[idx];
    if (target.isSystem) {
      throw AppDomainError(
        code: 'SYSTEM_CATEGORY_PROTECTED',
        message:
            'Built-in system category "${target.name}" cannot be deleted.',
        status: 409,
      );
    }

    final usedCount = state.materials
        .where((m) => m.effectiveCategoryCode == target.code)
        .length;
    if (usedCount > 0) {
      throw AppDomainError(
        code: 'CATEGORY_IN_USE',
        message:
            'Cannot delete category "${target.name}" because it is assigned to $usedCount material(s).',
        status: 409,
      );
    }

    final categories = existingCats.where((c) => c.id != target.id).toList();
    return (
      deletedCategory: target,
      state: ErpState(
        materials: state.materials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: categories,
        summary: state.summary,
      ),
    );
  }

  /// Processes a multi-item POS sale transaction (`BR-002`, `BR-003`, `BR-004`, `BR-005`).
  static ({ErpState state, SaleTransaction sale}) recordSale(
    ErpState state,
    RecordSaleInput input, {
    String? nowIso,
  }) {
    if (input.items.isEmpty) {
      throw const AppDomainError(
        code: 'EMPTY_SALE_CART',
        message: 'A sale transaction must contain at least one line item.',
        status: 400,
      );
    }

    // Aggregate duplicate materialIds before stock check (BR-003)
    final Map<String, ({double quantity, double unitSellingPrice})> aggregated =
        {};
    for (final line in input.items) {
      if (line.materialId.trim().isEmpty) {
        throw const AppDomainError(
          code: 'VALIDATION_ERROR',
          message: 'Each sale line item must specify a valid materialId.',
          status: 400,
        );
      }
      if (line.quantity.isNaN || line.quantity <= 0) {
        throw const AppDomainError(
          code: 'VALIDATION_ERROR',
          message: 'Sale quantity must be strictly greater than zero (> 0).',
          status: 400,
        );
      }
      if (line.unitSellingPrice.isNaN || line.unitSellingPrice < 0) {
        throw const AppDomainError(
          code: 'VALIDATION_ERROR',
          message: 'Unit selling price (ETB) must be >= 0.',
          status: 400,
        );
      }

      final existing = aggregated[line.materialId];
      if (existing != null) {
        aggregated[line.materialId] = (
          quantity: round2(existing.quantity + line.quantity),
          unitSellingPrice: round2(line.unitSellingPrice),
        );
      } else {
        aggregated[line.materialId] = (
          quantity: round2(line.quantity),
          unitSellingPrice: round2(line.unitSellingPrice),
        );
      }
    }

    final materialMap = {for (final m in state.materials) m.id: m};

    for (final entry in aggregated.entries) {
      final mat = materialMap[entry.key];
      if (mat == null) {
        throw AppDomainError(
          code: 'MATERIAL_NOT_FOUND',
          message: 'Material "${entry.key}" does not exist.',
          status: 404,
        );
      }
      if (mat.isArchived) {
        throw AppDomainError(
          code: 'MATERIAL_ARCHIVED',
          message:
              'Material "${mat.name}" is archived and cannot be sold. Restore it first.',
          status: 409,
        );
      }
      if (entry.value.quantity > mat.currentStock) {
        throw AppDomainError(
          code: 'INSUFFICIENT_STOCK',
          message:
              'Insufficient stock for "${mat.name}". Available: ${formatQty(mat.currentStock)} ${mat.unit.code}, Requested: ${formatQty(entry.value.quantity)} ${mat.unit.code}.',
          status: 422,
          details: {
            'materialId': mat.id,
            'materialName': mat.name,
            'availableStock': mat.currentStock,
            'requestedQuantity': entry.value.quantity,
            'unit': mat.unit.code,
          },
        );
      }
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final List<SaleLineItem> saleLines = [];
    double totalAmount = 0;
    double totalCost = 0;
    double totalProfit = 0;

    final updatedMaterials = state.materials.map((m) {
      final agg = aggregated[m.id];
      if (agg == null) return m;

      final lineTotal = round2(agg.quantity * agg.unitSellingPrice);
      final lineCost = round2(agg.quantity * m.unitCost);
      final lineProfit =
          round2(agg.quantity * (agg.unitSellingPrice - m.unitCost));

      saleLines.add(
        SaleLineItem(
          id: 'sli-${_shortId()}',
          materialId: m.id,
          materialName: m.name,
          unit: m.unit,
          quantity: agg.quantity,
          unitSellingPrice: agg.unitSellingPrice,
          unitCostSnapshot: m.unitCost,
          lineTotal: lineTotal,
          lineProfit: lineProfit,
        ),
      );

      totalAmount = round2(totalAmount + lineTotal);
      totalCost = round2(totalCost + lineCost);
      totalProfit = round2(totalProfit + lineProfit);

      return m.copyWith(
        currentStock: round2(m.currentStock - agg.quantity),
        updatedAt: timestamp,
      );
    }).toList();

    final sale = SaleTransaction(
      id: 'sale-${_shortId()}',
      items: saleLines,
      totalAmount: totalAmount,
      totalCost: totalCost,
      totalProfit: totalProfit,
      customerNote: input.customerNote.trim(),
      createdAt: timestamp,
    );

    final sales = [sale, ...state.sales];
    return (
      sale: sale,
      state: ErpState(
        materials: updatedMaterials,
        sales: sales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Processes a supplier Stock-In delivery and recalculates weighted-average cost (`BR-006`).
  static ({ErpState state, StockInRecord stockIn, MaterialItem material})
      recordStockIn(
    ErpState state,
    RecordStockInInput input, {
    String? nowIso,
  }) {
    if (input.quantityAdded.isNaN || input.quantityAdded <= 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message:
            'Stock-In quantityAdded must be strictly greater than zero (> 0).',
        status: 400,
      );
    }
    if (input.unitPurchaseCost.isNaN || input.unitPurchaseCost < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message:
            'Unit purchase cost (ETB) must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    final idx = state.materials.indexWhere((m) => m.id == input.materialId);
    if (idx == -1) {
      throw AppDomainError(
        code: 'MATERIAL_NOT_FOUND',
        message: 'Material "${input.materialId}" was not found.',
        status: 404,
      );
    }

    final existing = state.materials[idx];
    if (existing.isArchived) {
      throw AppDomainError(
        code: 'MATERIAL_ARCHIVED',
        message:
            'Material "${existing.name}" is archived and cannot receive stock. Restore it first.',
        status: 409,
      );
    }

    final previousStock = existing.currentStock;
    final previousUnitCost = existing.unitCost;
    final quantityAdded = round2(input.quantityAdded);
    final unitPurchaseCost = round2(input.unitPurchaseCost);
    final newStock = round2(previousStock + quantityAdded);

    final newUnitCost = newStock > 0
        ? round2(
            ((previousStock * previousUnitCost) +
                    (quantityAdded * unitPurchaseCost)) /
                newStock,
          )
        : unitPurchaseCost;

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final updatedMaterial = existing.copyWith(
      currentStock: newStock,
      unitCost: newUnitCost,
      updatedAt: timestamp,
    );

    final record = StockInRecord(
      id: 'stin-${_shortId()}',
      materialId: existing.id,
      materialName: existing.name,
      unit: existing.unit,
      quantityAdded: quantityAdded,
      unitPurchaseCost: unitPurchaseCost,
      totalPurchaseCost: round2(quantityAdded * unitPurchaseCost),
      previousStock: previousStock,
      newStock: newStock,
      previousUnitCost: previousUnitCost,
      newUnitCost: newUnitCost,
      supplierNote: input.supplierNote.trim(),
      createdAt: timestamp,
    );

    final materials = [...state.materials];
    materials[idx] = updatedMaterial;
    final stockIns = [record, ...state.stockIns];

    return (
      stockIn: record,
      material: updatedMaterial,
      state: ErpState(
        materials: materials,
        sales: state.sales,
        stockIns: stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Processes a physical Ground-Stock Audit reconciliation (`FR-015`–`FR-017`, `AC-005`).
  static ({ErpState state, StockAuditRecord audit}) recordStockAudit(
    ErpState state,
    RecordStockAuditInput input, {
    String? nowIso,
  }) {
    if (input.adjustments.isEmpty) {
      throw const AppDomainError(
        code: 'EMPTY_AUDIT_PAYLOAD',
        message:
            'Stock audit must include at least one material physical count.',
        status: 400,
      );
    }

    final Map<String, double> countByMaterialId = {};
    for (final adj in input.adjustments) {
      if (adj.physicalCount.isNaN || adj.physicalCount < 0) {
        throw const AppDomainError(
          code: 'VALIDATION_ERROR',
          message: 'Physical count cannot be negative (< 0).',
          status: 400,
        );
      }
      countByMaterialId[adj.materialId] = round2(adj.physicalCount);
    }

    final materialMap = {for (final m in state.materials) m.id: m};
    for (final matId in countByMaterialId.keys) {
      final mat = materialMap[matId];
      if (mat == null) {
        throw AppDomainError(
          code: 'MATERIAL_NOT_FOUND',
          message: 'Material "$matId" was not found.',
          status: 404,
        );
      }
      if (mat.isArchived) {
        throw AppDomainError(
          code: 'MATERIAL_ARCHIVED',
          message:
              'Archived material "${mat.name}" cannot be included in an active stock audit.',
          status: 409,
        );
      }
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final List<AuditLineItem> auditLines = [];

    final updatedMaterials = state.materials.map((m) {
      final physicalCount = countByMaterialId[m.id];
      if (physicalCount == null) return m;

      final expectedStock = m.currentStock;
      final variance = round2(physicalCount - expectedStock);

      auditLines.add(
        AuditLineItem(
          materialId: m.id,
          materialName: m.name,
          unit: m.unit,
          expectedStock: expectedStock,
          physicalCount: physicalCount,
          variance: variance,
          unitCostSnapshot: m.unitCost,
        ),
      );

      return m.copyWith(
        currentStock: physicalCount,
        updatedAt: timestamp,
      );
    }).toList();

    final audit = StockAuditRecord(
      id: 'aud-${_shortId()}',
      adjustments: auditLines,
      auditNote: input.auditNote.trim(),
      createdAt: timestamp,
    );

    final audits = [audit, ...state.audits];
    return (
      audit: audit,
      state: ErpState(
        materials: updatedMaterials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Reverses a completed sale transaction, restoring sold inventory quantities (`FR-029`, `BR-013`).
  static ({ErpState state, SaleTransaction sale}) reverseSaleTransaction(
    ErpState state,
    String saleId, {
    required String reason,
    required String actorUsername,
    String? nowIso,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'A reversal reason is required to reverse a sale transaction.',
        status: 400,
      );
    }

    final saleIdx = state.sales.indexWhere((s) => s.id == saleId);
    if (saleIdx == -1) {
      throw AppDomainError(
        code: 'SALE_NOT_FOUND',
        message: 'Sale transaction "$saleId" was not found.',
        status: 404,
      );
    }

    final existingSale = state.sales[saleIdx];
    if (existingSale.isReversed) {
      throw AppDomainError(
        code: 'ALREADY_REVERSED',
        message: 'Sale transaction "${existingSale.id}" has already been reversed.',
        status: 409,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final Map<String, double> qtyToRestore = {};
    for (final line in existingSale.items) {
      qtyToRestore[line.materialId] =
          round2((qtyToRestore[line.materialId] ?? 0) + line.quantity);
    }

    final updatedMaterials = state.materials.map((m) {
      final addBack = qtyToRestore[m.id];
      if (addBack == null) return m;
      return m.copyWith(
        currentStock: round2(m.currentStock + addBack),
        updatedAt: timestamp,
      );
    }).toList();

    final reversedSale = existingSale.copyWith(
      isReversed: true,
      reversedAt: timestamp,
      reversedBy: actorUsername,
      reversalReason: cleanReason,
    );

    final updatedSales = [...state.sales];
    updatedSales[saleIdx] = reversedSale;

    return (
      sale: reversedSale,
      state: ErpState(
        materials: updatedMaterials,
        sales: updatedSales,
        stockIns: state.stockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: updatedSales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Reverses a completed Stock-In record, deducting added stock and restoring unit cost (`FR-030`, `BR-014`).
  static ({ErpState state, StockInRecord stockIn}) reverseStockInRecord(
    ErpState state,
    String stockInId, {
    required String reason,
    required String actorUsername,
    String? nowIso,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'A reversal reason is required to reverse a stock-in record.',
        status: 400,
      );
    }

    final stinIdx = state.stockIns.indexWhere((s) => s.id == stockInId);
    if (stinIdx == -1) {
      throw AppDomainError(
        code: 'STOCK_IN_NOT_FOUND',
        message: 'Stock-In record "$stockInId" was not found.',
        status: 404,
      );
    }

    final existingStin = state.stockIns[stinIdx];
    if (existingStin.isReversed) {
      throw AppDomainError(
        code: 'ALREADY_REVERSED',
        message: 'Stock-In record "${existingStin.id}" has already been reversed.',
        status: 409,
      );
    }

    final matIdx =
        state.materials.indexWhere((m) => m.id == existingStin.materialId);
    if (matIdx == -1) {
      throw AppDomainError(
        code: 'MATERIAL_NOT_FOUND',
        message: 'Material "${existingStin.materialId}" was not found.',
        status: 404,
      );
    }

    final mat = state.materials[matIdx];
    if (mat.currentStock < existingStin.quantityAdded) {
      throw AppDomainError(
        code: 'REVERSAL_WOULD_CAUSE_NEGATIVE_STOCK',
        message:
            'Cannot reverse Stock-In "${existingStin.id}" because current stock of "${mat.name}" (${formatQty(mat.currentStock)} ${mat.unit.code}) is less than the stocked-in quantity (${formatQty(existingStin.quantityAdded)} ${mat.unit.code}).',
        status: 422,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final restoredStock = round2(mat.currentStock - existingStin.quantityAdded);
    final updatedMat = mat.copyWith(
      currentStock: restoredStock,
      unitCost: existingStin.previousUnitCost,
      updatedAt: timestamp,
    );

    final updatedMaterials = [...state.materials];
    updatedMaterials[matIdx] = updatedMat;

    final reversedStin = existingStin.copyWith(
      isReversed: true,
      reversedAt: timestamp,
      reversedBy: actorUsername,
      reversalReason: cleanReason,
    );

    final updatedStockIns = [...state.stockIns];
    updatedStockIns[stinIdx] = reversedStin;

    return (
      stockIn: reversedStin,
      state: ErpState(
        materials: updatedMaterials,
        sales: state.sales,
        stockIns: updatedStockIns,
        audits: state.audits,
        categories: state.categories,
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }

  /// Reverses a completed Stock Audit record by subtracting the applied variance (`FR-030`, `BR-014`).
  static ({ErpState state, StockAuditRecord audit}) reverseStockAuditRecord(
    ErpState state,
    String auditId, {
    required String reason,
    required String actorUsername,
    String? nowIso,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'A reversal reason is required to reverse a stock audit.',
        status: 400,
      );
    }

    final audIdx = state.audits.indexWhere((a) => a.id == auditId);
    if (audIdx == -1) {
      throw AppDomainError(
        code: 'AUDIT_NOT_FOUND',
        message: 'Stock Audit record "$auditId" was not found.',
        status: 404,
      );
    }

    final existingAudit = state.audits[audIdx];
    if (existingAudit.isReversed) {
      throw AppDomainError(
        code: 'ALREADY_REVERSED',
        message: 'Stock Audit "${existingAudit.id}" has already been reversed.',
        status: 409,
      );
    }

    final materialMap = {for (final m in state.materials) m.id: m};
    for (final adj in existingAudit.adjustments) {
      final mat = materialMap[adj.materialId];
      if (mat == null) {
        throw AppDomainError(
          code: 'MATERIAL_NOT_FOUND',
          message: 'Material "${adj.materialId}" was not found.',
          status: 404,
        );
      }
      final revertedStock = round2(mat.currentStock - adj.variance);
      if (revertedStock < 0) {
        throw AppDomainError(
          code: 'REVERSAL_WOULD_CAUSE_NEGATIVE_STOCK',
          message:
              'Cannot reverse Stock Audit "${existingAudit.id}" because reversing variance (${formatQty(adj.variance)}) on "${mat.name}" would result in negative stock (${formatQty(revertedStock)}).',
          status: 422,
        );
      }
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final Map<String, double> varianceByMatId = {
      for (final adj in existingAudit.adjustments) adj.materialId: adj.variance,
    };

    final updatedMaterials = state.materials.map((m) {
      final variance = varianceByMatId[m.id];
      if (variance == null) return m;
      return m.copyWith(
        currentStock: round2(m.currentStock - variance),
        updatedAt: timestamp,
      );
    }).toList();

    final reversedAudit = existingAudit.copyWith(
      isReversed: true,
      reversedAt: timestamp,
      reversedBy: actorUsername,
      reversalReason: cleanReason,
    );

    final updatedAudits = [...state.audits];
    updatedAudits[audIdx] = reversedAudit;

    return (
      audit: reversedAudit,
      state: ErpState(
        materials: updatedMaterials,
        sales: state.sales,
        stockIns: state.stockIns,
        audits: updatedAudits,
        categories: state.categories,
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }
}
