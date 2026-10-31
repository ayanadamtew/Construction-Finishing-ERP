import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/domain_error.dart';
import '../../domain/models/erp_models.dart';

/// Optional REST API client matching `docs/API_CONTRACT.md` for syncing
/// with the local Express companion server (`http://10.0.2.2:3000/api` on Android emulator).
class ErpApiClient {
  final String baseUrl;
  final http.Client _client;

  ErpApiClient({
    this.baseUrl = 'http://10.0.2.2:3000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<ErpState> fetchState() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/state'))
        .timeout(const Duration(seconds: 5));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final err = body['error'] as Map<String, dynamic>?;
      throw AppDomainError(
        code: (err?['code'] as String?) ?? 'API_ERROR',
        message: (err?['message'] as String?) ?? 'Failed to fetch server state',
        status: response.statusCode,
      );
    }

    final data = body['data'] as Map<String, dynamic>;
    return ErpState(
      materials: (data['materials'] as List<dynamic>)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sales: (data['sales'] as List<dynamic>)
          .map((e) => SaleTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      stockIns: (data['stockIns'] as List<dynamic>)
          .map((e) => StockInRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      audits: (data['audits'] as List<dynamic>)
          .map((e) => StockAuditRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: StoreSummary.fromJson(data['summary'] as Map<String, dynamic>),
    );
  }
}
