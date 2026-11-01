import '../../core/constants/erp_constants.dart';

class MaterialItem {
  final String id;
  final String name;
  final MaterialCategory category;
  final String specs;
  final MaterialUnit unit;
  final double currentStock;
  final double minStockLevel;
  final double unitCost;
  final double defaultSellingPrice;
  final String createdAt;
  final String updatedAt;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.specs,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.unitCost,
    required this.defaultSellingPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock <= minStockLevel;

  MaterialItem copyWith({
    String? id,
    String? name,
    MaterialCategory? category,
    String? specs,
    MaterialUnit? unit,
    double? currentStock,
    double? minStockLevel,
    double? unitCost,
    double? defaultSellingPrice,
    String? createdAt,
    String? updatedAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      specs: specs ?? this.specs,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      unitCost: unitCost ?? this.unitCost,
      defaultSellingPrice: defaultSellingPrice ?? this.defaultSellingPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.code,
        'specs': specs,
        'unit': unit.code,
        'currentStock': currentStock,
        'minStockLevel': minStockLevel,
        'unitCost': unitCost,
        'defaultSellingPrice': defaultSellingPrice,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: MaterialCategory.fromCode(json['category'] as String),
      specs: (json['specs'] as String?) ?? '',
      unit: MaterialUnit.fromCode(json['unit'] as String),
      currentStock: (json['currentStock'] as num).toDouble(),
      minStockLevel: (json['minStockLevel'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      defaultSellingPrice: (json['defaultSellingPrice'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class SaleLineItem {
  final String id;
  final String materialId;
  final String materialName;
  final MaterialUnit unit;
  final double quantity;
  final double unitSellingPrice;
  final double unitCostSnapshot;
  final double lineTotal;
  final double lineProfit;

  const SaleLineItem({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitCostSnapshot,
    required this.lineTotal,
    required this.lineProfit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'materialId': materialId,
        'materialName': materialName,
        'unit': unit.code,
        'quantity': quantity,
        'unitSellingPrice': unitSellingPrice,
        'unitCostSnapshot': unitCostSnapshot,
        'lineTotal': lineTotal,
        'lineProfit': lineProfit,
      };

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    final materialId = json['materialId'] as String;
    return SaleLineItem(
      id: (json['id'] as String?) ?? 'sli_$materialId',
      materialId: materialId,
      materialName: json['materialName'] as String,
      unit: MaterialUnit.fromCode(json['unit'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitSellingPrice: (json['unitSellingPrice'] as num).toDouble(),
      unitCostSnapshot: (json['unitCostSnapshot'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      lineProfit: (json['lineProfit'] as num).toDouble(),
    );
  }
}

class SaleTransaction {
  final String id;
  final List<SaleLineItem> items;
  final double totalAmount;
  final double totalCost;
  final double totalProfit;
  final String customerNote;
  final String createdAt;

  const SaleTransaction({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.totalCost,
    required this.totalProfit,
    required this.customerNote,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'totalRevenue': totalAmount,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'customerNote': customerNote,
        'createdAt': createdAt,
      };

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    final totalAmount =
        ((json['totalAmount'] ?? json['totalRevenue'] ?? 0) as num).toDouble();
    final totalProfit = ((json['totalProfit'] ?? 0) as num).toDouble();
    final totalCost = json['totalCost'] != null
        ? (json['totalCost'] as num).toDouble()
        : (totalAmount - totalProfit);

    return SaleTransaction(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => SaleLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: totalAmount,
      totalCost: totalCost,
      totalProfit: totalProfit,
      customerNote: (json['customerNote'] as String?) ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}

class StockInRecord {
  final String id;
  final String materialId;
  final String materialName;
  final MaterialUnit unit;
  final double quantityAdded;
  final double unitPurchaseCost;
  final double totalPurchaseCost;
  final double previousStock;
  final double newStock;
  final double previousUnitCost;
  final double newUnitCost;
  final String supplierNote;
  final String createdAt;

  const StockInRecord({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.quantityAdded,
    required this.unitPurchaseCost,
    required this.totalPurchaseCost,
    required this.previousStock,
    required this.newStock,
    required this.previousUnitCost,
    required this.newUnitCost,
    required this.supplierNote,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'materialId': materialId,
        'materialName': materialName,
        'unit': unit.code,
        'quantityAdded': quantityAdded,
        'unitPurchaseCost': unitPurchaseCost,
        'totalPurchaseCost': totalPurchaseCost,
        'totalCost': totalPurchaseCost,
        'previousStock': previousStock,
        'newStock': newStock,
        'previousUnitCost': previousUnitCost,
        'newUnitCost': newUnitCost,
        'supplierNote': supplierNote,
        'createdAt': createdAt,
      };

  factory StockInRecord.fromJson(Map<String, dynamic> json) {
    final unitPurchaseCost = (json['unitPurchaseCost'] as num).toDouble();
    final totalPurchaseCost =
        ((json['totalPurchaseCost'] ?? json['totalCost'] ?? 0) as num)
            .toDouble();
    return StockInRecord(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      unit: MaterialUnit.fromCode(json['unit'] as String),
      quantityAdded: (json['quantityAdded'] as num).toDouble(),
      unitPurchaseCost: unitPurchaseCost,
      totalPurchaseCost: totalPurchaseCost,
      previousStock: (json['previousStock'] as num).toDouble(),
      newStock: (json['newStock'] as num).toDouble(),
      previousUnitCost:
          ((json['previousUnitCost'] ?? unitPurchaseCost) as num).toDouble(),
      newUnitCost:
          ((json['newUnitCost'] ?? unitPurchaseCost) as num).toDouble(),
      supplierNote: (json['supplierNote'] as String?) ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}

class AuditLineItem {
  final String materialId;
  final String materialName;
  final MaterialUnit unit;
  final double expectedStock;
  final double physicalCount;
  final double variance;
  final double unitCostSnapshot;

  const AuditLineItem({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.expectedStock,
    required this.physicalCount,
    required this.variance,
    required this.unitCostSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'materialName': materialName,
        'unit': unit.code,
        'expectedStock': expectedStock,
        'physicalCount': physicalCount,
        'variance': variance,
        'unitCostSnapshot': unitCostSnapshot,
      };

  factory AuditLineItem.fromJson(Map<String, dynamic> json) {
    return AuditLineItem(
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      unit: MaterialUnit.fromCode(json['unit'] as String),
      expectedStock: (json['expectedStock'] as num).toDouble(),
      physicalCount: (json['physicalCount'] as num).toDouble(),
      variance: (json['variance'] as num).toDouble(),
      unitCostSnapshot: (json['unitCostSnapshot'] as num).toDouble(),
    );
  }
}

class StockAuditRecord {
  final String id;
  final List<AuditLineItem> adjustments;
  final String auditNote;
  final String createdAt;

  const StockAuditRecord({
    required this.id,
    required this.adjustments,
    required this.auditNote,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'adjustments': adjustments.map((e) => e.toJson()).toList(),
        'auditNote': auditNote,
        'note': auditNote,
        'createdAt': createdAt,
      };

  factory StockAuditRecord.fromJson(Map<String, dynamic> json) {
    return StockAuditRecord(
      id: json['id'] as String,
      adjustments: (json['adjustments'] as List<dynamic>)
          .map((e) => AuditLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditNote: ((json['auditNote'] ?? json['note']) as String?) ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}

class StoreSummary {
  final int totalMaterials;
  final int lowStockCount;
  final double totalStockValuationCost;
  final double totalStockValuationRetail;
  final double todaySalesRevenue;
  final double todaySalesProfit;
  final double cumulativeSalesRevenue;
  final double cumulativeSalesProfit;
  final int totalSalesCount;

  const StoreSummary({
    required this.totalMaterials,
    required this.lowStockCount,
    required this.totalStockValuationCost,
    required this.totalStockValuationRetail,
    required this.todaySalesRevenue,
    required this.todaySalesProfit,
    required this.cumulativeSalesRevenue,
    required this.cumulativeSalesProfit,
    required this.totalSalesCount,
  });

  factory StoreSummary.fromJson(
    Map<String, dynamic> json, {
    int fallbackTotalMaterials = 0,
    int fallbackTotalSalesCount = 0,
  }) {
    final cumulativeRevenue = ((json['cumulativeSalesRevenue'] ??
                json['totalRevenue'] ??
                0) as num)
        .toDouble();
    final cumulativeProfit =
        ((json['cumulativeSalesProfit'] ?? json['totalProfit'] ?? 0) as num)
            .toDouble();

    return StoreSummary(
      totalMaterials:
          ((json['totalMaterials'] ?? fallbackTotalMaterials) as num).toInt(),
      lowStockCount: ((json['lowStockCount'] ?? 0) as num).toInt(),
      totalStockValuationCost: ((json['totalStockValuationCost'] ??
                  json['inventoryCostValue'] ??
                  0) as num)
          .toDouble(),
      totalStockValuationRetail: ((json['totalStockValuationRetail'] ??
                  json['inventoryRetailValue'] ??
                  0) as num)
          .toDouble(),
      todaySalesRevenue:
          ((json['todaySalesRevenue'] ?? cumulativeRevenue) as num).toDouble(),
      todaySalesProfit:
          ((json['todaySalesProfit'] ?? cumulativeProfit) as num).toDouble(),
      cumulativeSalesRevenue: cumulativeRevenue,
      cumulativeSalesProfit: cumulativeProfit,
      totalSalesCount:
          ((json['totalSalesCount'] ?? fallbackTotalSalesCount) as num).toInt(),
    );
  }
}

class ErpState {
  final List<MaterialItem> materials;
  final List<SaleTransaction> sales;
  final List<StockInRecord> stockIns;
  final List<StockAuditRecord> audits;
  final StoreSummary summary;

  const ErpState({
    required this.materials,
    required this.sales,
    required this.stockIns,
    required this.audits,
    required this.summary,
  });
}

class RegisterMaterialInput {
  final String name;
  final MaterialCategory category;
  final String specs;
  final MaterialUnit unit;
  final double currentStock;
  final double minStockLevel;
  final double unitCost;
  final double defaultSellingPrice;

  const RegisterMaterialInput({
    required this.name,
    required this.category,
    this.specs = '',
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.unitCost,
    required this.defaultSellingPrice,
  });
}

class UpdateMaterialInput {
  final String? name;
  final MaterialCategory? category;
  final String? specs;
  final double? minStockLevel;
  final double? defaultSellingPrice;
  final Map<String, dynamic>? rawAttemptedFields;

  const UpdateMaterialInput({
    this.name,
    this.category,
    this.specs,
    this.minStockLevel,
    this.defaultSellingPrice,
    this.rawAttemptedFields,
  });
}

class SaleCartLineInput {
  final String materialId;
  final double quantity;
  final double unitSellingPrice;

  const SaleCartLineInput({
    required this.materialId,
    required this.quantity,
    required this.unitSellingPrice,
  });
}

class RecordSaleInput {
  final List<SaleCartLineInput> items;
  final String customerNote;

  const RecordSaleInput({
    required this.items,
    this.customerNote = '',
  });
}

class RecordStockInInput {
  final String materialId;
  final double quantityAdded;
  final double unitPurchaseCost;
  final String supplierNote;

  const RecordStockInInput({
    required this.materialId,
    required this.quantityAdded,
    required this.unitPurchaseCost,
    this.supplierNote = '',
  });
}

class AuditAdjustmentInput {
  final String materialId;
  final double physicalCount;

  const AuditAdjustmentInput({
    required this.materialId,
    required this.physicalCount,
  });
}

class RecordStockAuditInput {
  final List<AuditAdjustmentInput> adjustments;
  final String auditNote;

  const RecordStockAuditInput({
    required this.adjustments,
    this.auditNote = '',
  });
}
