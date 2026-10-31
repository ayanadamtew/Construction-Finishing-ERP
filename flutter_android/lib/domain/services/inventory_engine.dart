import 'package:uuid/uuid.dart';
import '../../core/constants/erp_constants.dart';
import '../../core/errors/domain_error.dart';
import '../models/erp_models.dart';

const _uuid = Uuid();

/// Pure domain engine enforcing all business rules (`BR-001` through `BR-008`)
/// and acceptance criteria (`AC-001` through `AC-006`).
class InventoryEngine {
  static StoreSummary calculateSummary({
    required List<MaterialItem> materials,
    required List<SaleTransaction> sales,
    String? referenceDateIso,
  }) {
    final todayPrefix =
        (referenceDateIso ?? DateTime.now().toUtc().toIso8601String())
            .substring(0, 10);

    int lowStockCount = 0;
    double totalStockValuationCost = 0;
    double totalStockValuationRetail = 0;

    for (final m in materials) {
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

    for (final sale in sales) {
      cumulativeSalesRevenue += sale.totalAmount;
      cumulativeSalesProfit += sale.totalProfit;
      if (sale.createdAt.startsWith(todayPrefix)) {
        todaySalesRevenue += sale.totalAmount;
        todaySalesProfit += sale.totalProfit;
      }
    }

    return StoreSummary(
      totalMaterials: materials.length,
      lowStockCount: lowStockCount,
      totalStockValuationCost: round2(totalStockValuationCost),
      totalStockValuationRetail: round2(totalStockValuationRetail),
      todaySalesRevenue: round2(todaySalesRevenue),
      todaySalesProfit: round2(todaySalesProfit),
      cumulativeSalesRevenue: round2(cumulativeSalesRevenue),
      cumulativeSalesProfit: round2(cumulativeSalesProfit),
      totalSalesCount: sales.length,
    );
  }

  static ErpState createSeedState({String? nowIso}) {
    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
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
        message: 'Material name is required and must be between 1 and 120 characters.',
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
        message: 'Minimum stock alert level must be a non-negative number (>= 0).',
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
        message: 'Default selling price (ETB) must be a non-negative number (>= 0).',
        status: 400,
      );
    }

    final timestamp = nowIso ?? DateTime.now().toUtc().toIso8601String();
    final material = MaterialItem(
      id: 'mat-${_uuid.v4().substring(0, 8)}',
      name: name,
      category: input.category,
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
    final updated = existing.copyWith(
      name: nextName,
      category: input.category ?? existing.category,
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
        summary: calculateSummary(
          materials: materials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
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
          id: 'sli-${_uuid.v4().substring(0, 8)}',
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
      id: 'sale-${_uuid.v4().substring(0, 8)}',
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
        message: 'Stock-In quantityAdded must be strictly greater than zero (> 0).',
        status: 400,
      );
    }
    if (input.unitPurchaseCost.isNaN || input.unitPurchaseCost < 0) {
      throw const AppDomainError(
        code: 'VALIDATION_ERROR',
        message: 'Unit purchase cost (ETB) must be a non-negative number (>= 0).',
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
      id: 'stin-${_uuid.v4().substring(0, 8)}',
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
        message: 'Stock audit must include at least one material physical count.',
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
      if (!materialMap.containsKey(matId)) {
        throw AppDomainError(
          code: 'MATERIAL_NOT_FOUND',
          message: 'Material "$matId" was not found.',
          status: 404,
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
      id: 'aud-${_uuid.v4().substring(0, 8)}',
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
        summary: calculateSummary(
          materials: updatedMaterials,
          sales: state.sales,
          referenceDateIso: timestamp,
        ),
      ),
    );
  }
}
