import '../../core/constants/erp_constants.dart';

class UserAccount {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String passwordHash;
  final bool isActive;
  final String createdAt;
  final String? lastLoginAt;

  const UserAccount({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.passwordHash,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  UserAccount copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    UserRole? role,
    String? passwordHash,
    bool? isActive,
    String? createdAt,
    String? lastLoginAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role.code,
        'passwordHash': passwordHash,
        'isActive': isActive,
        'createdAt': createdAt,
        'lastLoginAt': lastLoginAt,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] as String?) ?? (json['username'] as String),
      role: UserRole.fromCode((json['role'] as String?) ?? 'staff'),
      passwordHash: (json['passwordHash'] as String?) ?? '',
      isActive: json['isActive'] is bool
          ? (json['isActive'] as bool)
          : ((json['isActive'] as num?) ?? 1) != 0,
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String?,
    );
  }
}

class PublicUser {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String createdAt;
  final String? lastLoginAt;

  const PublicUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role.code,
        'isActive': isActive,
        'createdAt': createdAt,
        'lastLoginAt': lastLoginAt,
      };

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] as String?) ?? (json['username'] as String),
      role: UserRole.fromCode((json['role'] as String?) ?? 'staff'),
      isActive: json['isActive'] is bool
          ? (json['isActive'] as bool)
          : ((json['isActive'] as num?) ?? 1) != 0,
      createdAt: json['createdAt'] as String,
      lastLoginAt: json['lastLoginAt'] as String?,
    );
  }
}

class CategoryRecord {
  final String id;
  final String code;
  final String name;
  final bool isSystem;
  final String createdAt;
  final String? createdBy;

  const CategoryRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.isSystem,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'isSystem': isSystem,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };

  factory CategoryRecord.fromJson(Map<String, dynamic> json) {
    final String code = ((json['code'] ?? json['id'] ?? 'other') as String)
        .trim()
        .toLowerCase();
    return CategoryRecord(
      id: (json['id'] as String?) ?? 'cat-$code',
      code: code,
      name: (json['name'] as String?) ?? code,
      isSystem: json['isSystem'] is bool
          ? (json['isSystem'] as bool)
          : ((json['isSystem'] as num?) ?? 0) != 0,
      createdAt: (json['createdAt'] as String?) ??
          DateTime.now().toUtc().toIso8601String(),
      createdBy: json['createdBy'] as String?,
    );
  }
}

class MaterialItem {
  final String id;
  final String name;
  final MaterialCategory category;
  final String categoryCode;
  final String specs;
  final MaterialUnit unit;
  final double currentStock;
  final double minStockLevel;
  final double unitCost;
  final double defaultSellingPrice;
  final String createdAt;
  final String updatedAt;
  final bool isArchived;
  final String? archivedAt;
  final String? archivedBy;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    String? categoryCode,
    required this.specs,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.unitCost,
    required this.defaultSellingPrice,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
  }) : categoryCode = categoryCode ?? '';

  String get effectiveCategoryCode =>
      categoryCode.isNotEmpty ? categoryCode : category.code;

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock <= minStockLevel;

  MaterialItem copyWith({
    String? id,
    String? name,
    MaterialCategory? category,
    String? categoryCode,
    String? specs,
    MaterialUnit? unit,
    double? currentStock,
    double? minStockLevel,
    double? unitCost,
    double? defaultSellingPrice,
    String? createdAt,
    String? updatedAt,
    bool? isArchived,
    String? archivedAt,
    String? archivedBy,
    bool clearArchiveMetadata = false,
  }) {
    final nextCat = category ?? this.category;
    final nextCatCode = categoryCode ??
        (category != null ? category.code : effectiveCategoryCode);
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: nextCat,
      categoryCode: nextCatCode,
      specs: specs ?? this.specs,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      unitCost: unitCost ?? this.unitCost,
      defaultSellingPrice: defaultSellingPrice ?? this.defaultSellingPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt:
          clearArchiveMetadata ? null : (archivedAt ?? this.archivedAt),
      archivedBy:
          clearArchiveMetadata ? null : (archivedBy ?? this.archivedBy),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': effectiveCategoryCode,
        'specs': specs,
        'unit': unit.code,
        'currentStock': currentStock,
        'minStockLevel': minStockLevel,
        'unitCost': unitCost,
        'defaultSellingPrice': defaultSellingPrice,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isArchived': isArchived,
        'archivedAt': archivedAt,
        'archivedBy': archivedBy,
      };

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] as String?) ?? 'other';
    return MaterialItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: MaterialCategory.fromCode(rawCategory),
      categoryCode: rawCategory,
      specs: (json['specs'] as String?) ?? '',
      unit: MaterialUnit.fromCode(json['unit'] as String),
      currentStock: (json['currentStock'] as num).toDouble(),
      minStockLevel: (json['minStockLevel'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      defaultSellingPrice: (json['defaultSellingPrice'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      isArchived: json['isArchived'] is bool
          ? (json['isArchived'] as bool)
          : ((json['isArchived'] as num?) ?? 0) != 0,
      archivedAt: json['archivedAt'] as String?,
      archivedBy: json['archivedBy'] as String?,
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
  final bool isReversed;
  final String? reversedAt;
  final String? reversedBy;
  final String? reversalReason;

  const SaleTransaction({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.totalCost,
    required this.totalProfit,
    required this.customerNote,
    required this.createdAt,
    this.isReversed = false,
    this.reversedAt,
    this.reversedBy,
    this.reversalReason,
  });

  SaleTransaction copyWith({
    bool? isReversed,
    String? reversedAt,
    String? reversedBy,
    String? reversalReason,
  }) {
    return SaleTransaction(
      id: id,
      items: items,
      totalAmount: totalAmount,
      totalCost: totalCost,
      totalProfit: totalProfit,
      customerNote: customerNote,
      createdAt: createdAt,
      isReversed: isReversed ?? this.isReversed,
      reversedAt: reversedAt ?? this.reversedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'totalRevenue': totalAmount,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'customerNote': customerNote,
        'createdAt': createdAt,
        'isReversed': isReversed,
        'reversedAt': reversedAt,
        'reversedBy': reversedBy,
        'reversalReason': reversalReason,
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
      isReversed: json['isReversed'] is bool
          ? (json['isReversed'] as bool)
          : ((json['isReversed'] as num?) ?? 0) != 0,
      reversedAt: json['reversedAt'] as String?,
      reversedBy: json['reversedBy'] as String?,
      reversalReason: json['reversalReason'] as String?,
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
  final bool isReversed;
  final String? reversedAt;
  final String? reversedBy;
  final String? reversalReason;

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
    this.isReversed = false,
    this.reversedAt,
    this.reversedBy,
    this.reversalReason,
  });

  StockInRecord copyWith({
    bool? isReversed,
    String? reversedAt,
    String? reversedBy,
    String? reversalReason,
  }) {
    return StockInRecord(
      id: id,
      materialId: materialId,
      materialName: materialName,
      unit: unit,
      quantityAdded: quantityAdded,
      unitPurchaseCost: unitPurchaseCost,
      totalPurchaseCost: totalPurchaseCost,
      previousStock: previousStock,
      newStock: newStock,
      previousUnitCost: previousUnitCost,
      newUnitCost: newUnitCost,
      supplierNote: supplierNote,
      createdAt: createdAt,
      isReversed: isReversed ?? this.isReversed,
      reversedAt: reversedAt ?? this.reversedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }

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
        'isReversed': isReversed,
        'reversedAt': reversedAt,
        'reversedBy': reversedBy,
        'reversalReason': reversalReason,
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
      isReversed: json['isReversed'] is bool
          ? (json['isReversed'] as bool)
          : ((json['isReversed'] as num?) ?? 0) != 0,
      reversedAt: json['reversedAt'] as String?,
      reversedBy: json['reversedBy'] as String?,
      reversalReason: json['reversalReason'] as String?,
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
  final bool isReversed;
  final String? reversedAt;
  final String? reversedBy;
  final String? reversalReason;

  const StockAuditRecord({
    required this.id,
    required this.adjustments,
    required this.auditNote,
    required this.createdAt,
    this.isReversed = false,
    this.reversedAt,
    this.reversedBy,
    this.reversalReason,
  });

  StockAuditRecord copyWith({
    bool? isReversed,
    String? reversedAt,
    String? reversedBy,
    String? reversalReason,
  }) {
    return StockAuditRecord(
      id: id,
      adjustments: adjustments,
      auditNote: auditNote,
      createdAt: createdAt,
      isReversed: isReversed ?? this.isReversed,
      reversedAt: reversedAt ?? this.reversedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'adjustments': adjustments.map((e) => e.toJson()).toList(),
        'auditNote': auditNote,
        'note': auditNote,
        'createdAt': createdAt,
        'isReversed': isReversed,
        'reversedAt': reversedAt,
        'reversedBy': reversedBy,
        'reversalReason': reversalReason,
      };

  factory StockAuditRecord.fromJson(Map<String, dynamic> json) {
    return StockAuditRecord(
      id: json['id'] as String,
      adjustments: (json['adjustments'] as List<dynamic>)
          .map((e) => AuditLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditNote: ((json['auditNote'] ?? json['note']) as String?) ?? '',
      createdAt: json['createdAt'] as String,
      isReversed: json['isReversed'] is bool
          ? (json['isReversed'] as bool)
          : ((json['isReversed'] as num?) ?? 0) != 0,
      reversedAt: json['reversedAt'] as String?,
      reversedBy: json['reversedBy'] as String?,
      reversalReason: json['reversalReason'] as String?,
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
  final List<CategoryRecord> categories;
  final StoreSummary summary;

  const ErpState({
    required this.materials,
    required this.sales,
    required this.stockIns,
    required this.audits,
    this.categories = const [],
    required this.summary,
  });
}

class RegisterMaterialInput {
  final String name;
  final MaterialCategory category;
  final String? categoryCode;
  final String specs;
  final MaterialUnit unit;
  final double currentStock;
  final double minStockLevel;
  final double unitCost;
  final double defaultSellingPrice;

  const RegisterMaterialInput({
    required this.name,
    required this.category,
    this.categoryCode,
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
  final String? categoryCode;
  final String? specs;
  final MaterialUnit? unit;
  final double? minStockLevel;
  final double? defaultSellingPrice;
  final Map<String, dynamic>? rawAttemptedFields;

  const UpdateMaterialInput({
    this.name,
    this.category,
    this.categoryCode,
    this.specs,
    this.unit,
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

class CreateUserInput {
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String password;

  const CreateUserInput({
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.password,
  });
}

class CreateCategoryInput {
  final String code;
  final String name;

  const CreateCategoryInput({
    required this.code,
    required this.name,
  });
}
