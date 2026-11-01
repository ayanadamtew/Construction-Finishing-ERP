import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/domain_error.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/inventory_engine.dart';

/// REST API client matching all approved endpoints in `docs/API_CONTRACT.md`
/// for syncing with the Express companion server (`http://10.0.2.2:3000/api` on Android emulator).
class ErpApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeoutDuration;
  String? _authToken;

  ErpApiClient({
    this.baseUrl = 'http://10.0.2.2:3000/api',
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 5),
    String? authToken,
  })  : _client = client ?? http.Client(),
        _authToken = authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (_authToken != null && _authToken!.isNotEmpty)
          'Authorization': 'Bearer $_authToken',
      };

  Map<String, dynamic> _decodeAndCheck(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final Map<String, dynamic> body = response.body.isNotEmpty
        ? (jsonDecode(response.body) as Map<String, dynamic>)
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      final err = body['error'] as Map<String, dynamic>?;
      throw AppDomainError(
        code: (err?['code'] as String?) ?? 'INTERNAL_ERROR',
        message: (err?['message'] as String?) ?? fallbackMessage,
        status: response.statusCode,
        details: err?['details'] as Map<String, dynamic>?,
      );
    }

    return body['data'] is Map<String, dynamic>
        ? (body['data'] as Map<String, dynamic>)
        : body;
  }

  /// `POST /api/auth/login`
  Future<({String token, PublicUser user})> login(
    String usernameOrEmail,
    String password,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'usernameOrEmail': usernameOrEmail,
            'password': password,
          }),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to authenticate with companion server',
    );
    final token = data['token'] as String;
    final user = PublicUser.fromJson(data['user'] as Map<String, dynamic>);
    _authToken = token;
    return (token: token, user: user);
  }

  /// `POST /api/auth/logout`
  Future<void> logout() async {
    try {
      await _client
          .post(Uri.parse('$baseUrl/auth/logout'), headers: _jsonHeaders)
          .timeout(timeoutDuration);
    } finally {
      _authToken = null;
    }
  }

  /// 1. `GET /api/state`
  Future<ErpState> fetchState() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/state'), headers: _jsonHeaders)
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to fetch store state',
    );

    final materials = (data['materials'] as List<dynamic>)
        .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final sales = (data['sales'] as List<dynamic>)
        .map((e) => SaleTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final stockIns = (data['stockIns'] as List<dynamic>)
        .map((e) => StockInRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final audits = (data['audits'] as List<dynamic>)
        .map((e) => StockAuditRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final categories = data['categories'] != null
        ? (data['categories'] as List<dynamic>)
            .map((e) => CategoryRecord.fromJson(e as Map<String, dynamic>))
            .toList()
        : InventoryEngine.createDefaultCategories();

    return ErpState(
      materials: materials,
      sales: sales,
      stockIns: stockIns,
      audits: audits,
      categories: categories,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.where((m) => !m.isArchived).length,
        fallbackTotalSalesCount: sales.where((s) => !s.isReversed).length,
      ),
    );
  }

  /// 2. `POST /api/materials`
  Future<
      ({
        MaterialItem material,
        List<MaterialItem> materials,
        StoreSummary summary
      })> registerMaterial(RegisterMaterialInput input) async {
    final payload = {
      'name': input.name,
      'category': input.categoryCode ?? input.category.code,
      'specs': input.specs,
      'unit': input.unit.code,
      'initialStock': input.currentStock,
      'minStockLevel': input.minStockLevel,
      'unitCost': input.unitCost,
      'defaultSellingPrice': input.defaultSellingPrice,
    };

    final response = await _client
        .post(
          Uri.parse('$baseUrl/materials'),
          headers: _jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to register material',
    );

    final material =
        MaterialItem.fromJson(data['material'] as Map<String, dynamic>);
    final materials = data['materials'] != null
        ? (data['materials'] as List<dynamic>)
            .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MaterialItem>[material];

    return (
      material: material,
      materials: materials,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.length,
      ),
    );
  }

  /// 3. `PATCH /api/materials/:id`
  Future<
      ({
        MaterialItem material,
        List<MaterialItem> materials,
        StoreSummary summary
      })> updateMaterialMetadata(
    String materialId,
    UpdateMaterialInput input,
  ) async {
    final Map<String, dynamic> payload = {
      if (input.name != null) 'name': input.name,
      if (input.categoryCode != null)
        'category': input.categoryCode
      else if (input.category != null)
        'category': input.category!.code,
      if (input.specs != null) 'specs': input.specs,
      if (input.minStockLevel != null) 'minStockLevel': input.minStockLevel,
      if (input.defaultSellingPrice != null)
        'defaultSellingPrice': input.defaultSellingPrice,
      if (input.rawAttemptedFields != null) ...input.rawAttemptedFields!,
    };

    final response = await _client
        .patch(
          Uri.parse('$baseUrl/materials/$materialId'),
          headers: _jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to update material metadata',
    );

    final material =
        MaterialItem.fromJson(data['material'] as Map<String, dynamic>);
    final materials = data['materials'] != null
        ? (data['materials'] as List<dynamic>)
            .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MaterialItem>[material];

    return (
      material: material,
      materials: materials,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.length,
      ),
    );
  }

  /// `DELETE /api/materials/:id`
  Future<void> deleteMaterial(String materialId) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/materials/$materialId'),
          headers: _jsonHeaders,
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to delete material');
  }

  /// `POST /api/materials/:id/archive`
  Future<void> setMaterialArchivedStatus(
    String materialId,
    bool isArchived,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/materials/$materialId/archive'),
          headers: _jsonHeaders,
          body: jsonEncode({'isArchived': isArchived}),
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to update material archive status',
    );
  }

  /// 4. `POST /api/sales`
  Future<
      ({
        SaleTransaction sale,
        List<MaterialItem> materials,
        StoreSummary summary
      })> recordSale(RecordSaleInput input) async {
    final payload = {
      'customerNote': input.customerNote,
      'items': input.items
          .map((item) => {
                'materialId': item.materialId,
                'quantity': item.quantity,
                'unitSellingPrice': item.unitSellingPrice,
              })
          .toList(),
    };

    final response = await _client
        .post(
          Uri.parse('$baseUrl/sales'),
          headers: _jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to record sale transaction',
    );

    final sale =
        SaleTransaction.fromJson(data['sale'] as Map<String, dynamic>);
    final materials = (data['materials'] as List<dynamic>)
        .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      sale: sale,
      materials: materials,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.length,
      ),
    );
  }

  /// `POST /api/sales/:id/reverse`
  Future<void> reverseSale(String saleId, String reason) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/sales/$saleId/reverse'),
          headers: _jsonHeaders,
          body: jsonEncode({'reason': reason}),
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to reverse sale');
  }

  /// 5. `POST /api/stock-in`
  Future<
      ({
        StockInRecord stockIn,
        MaterialItem material,
        List<MaterialItem> materials,
        StoreSummary summary
      })> recordStockIn(RecordStockInInput input) async {
    final payload = {
      'materialId': input.materialId,
      'quantityAdded': input.quantityAdded,
      'unitPurchaseCost': input.unitPurchaseCost,
      'supplierNote': input.supplierNote,
    };

    final response = await _client
        .post(
          Uri.parse('$baseUrl/stock-in'),
          headers: _jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to record supplier stock-in',
    );

    final stockIn =
        StockInRecord.fromJson(data['stockIn'] as Map<String, dynamic>);
    final material =
        MaterialItem.fromJson(data['material'] as Map<String, dynamic>);
    final materials = data['materials'] != null
        ? (data['materials'] as List<dynamic>)
            .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MaterialItem>[material];

    return (
      stockIn: stockIn,
      material: material,
      materials: materials,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.length,
      ),
    );
  }

  /// `POST /api/stock-in/:id/reverse`
  Future<void> reverseStockIn(String stockInId, String reason) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/stock-in/$stockInId/reverse'),
          headers: _jsonHeaders,
          body: jsonEncode({'reason': reason}),
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to reverse stock-in');
  }

  /// 6. `POST /api/audits`
  Future<
      ({
        StockAuditRecord audit,
        List<MaterialItem> materials,
        StoreSummary summary
      })> recordStockAudit(RecordStockAuditInput input) async {
    final payload = {
      'note': input.auditNote,
      'items': input.adjustments
          .map((item) => {
                'materialId': item.materialId,
                'physicalCount': item.physicalCount,
              })
          .toList(),
    };

    final response = await _client
        .post(
          Uri.parse('$baseUrl/audits'),
          headers: _jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    final data = _decodeAndCheck(
      response,
      fallbackMessage: 'Failed to commit ground-stock audit',
    );

    final audit =
        StockAuditRecord.fromJson(data['audit'] as Map<String, dynamic>);
    final materials = (data['materials'] as List<dynamic>)
        .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      audit: audit,
      materials: materials,
      summary: StoreSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
        fallbackTotalMaterials: materials.length,
      ),
    );
  }

  /// `POST /api/audits/:id/reverse`
  Future<void> reverseAudit(String auditId, String reason) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/audits/$auditId/reverse'),
          headers: _jsonHeaders,
          body: jsonEncode({'reason': reason}),
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to reverse stock audit');
  }

  /// `POST /api/categories`
  Future<void> createCategory(CreateCategoryInput input) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/categories'),
          headers: _jsonHeaders,
          body: jsonEncode({'code': input.code, 'name': input.name}),
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to create category');
  }

  /// `DELETE /api/categories/:id`
  Future<void> deleteCategory(String categoryIdOrCode) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/categories/$categoryIdOrCode'),
          headers: _jsonHeaders,
        )
        .timeout(timeoutDuration);
    _decodeAndCheck(response, fallbackMessage: 'Failed to delete category');
  }
}
