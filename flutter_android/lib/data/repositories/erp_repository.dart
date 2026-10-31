import '../../domain/models/erp_models.dart';
import '../../domain/services/inventory_engine.dart';
import '../local/sqlite_database.dart';
import '../remote/erp_api_client.dart';

/// Offline-first repository coordinating local SQLite persistence (`Sqflite`),
/// pure domain validation (`InventoryEngine`), and optional REST synchronization.
class ErpRepository {
  final SqliteDatabaseHelper _sqlite;
  final ErpApiClient _apiClient;

  ErpRepository({
    SqliteDatabaseHelper? sqlite,
    ErpApiClient? apiClient,
  })  : _sqlite = sqlite ?? SqliteDatabaseHelper(),
        _apiClient = apiClient ?? ErpApiClient();

  Future<ErpState> initialize() async {
    try {
      return await _sqlite.loadState();
    } catch (_) {
      return InventoryEngine.createSeedState();
    }
  }

  Future<ErpState> registerMaterial(
    ErpState current,
    RegisterMaterialInput input,
  ) async {
    final result = InventoryEngine.registerMaterial(current, input);
    await _sqlite.saveState(result.state);
    return result.state;
  }

  Future<ErpState> updateMaterialMetadata(
    ErpState current,
    String materialId,
    UpdateMaterialInput input,
  ) async {
    final result =
        InventoryEngine.updateMaterialMetadata(current, materialId, input);
    await _sqlite.saveState(result.state);
    return result.state;
  }

  Future<({ErpState state, SaleTransaction sale})> recordSale(
    ErpState current,
    RecordSaleInput input,
  ) async {
    final result = InventoryEngine.recordSale(current, input);
    await _sqlite.saveState(result.state);
    return result;
  }

  Future<({ErpState state, StockInRecord stockIn})> recordStockIn(
    ErpState current,
    RecordStockInInput input,
  ) async {
    final result = InventoryEngine.recordStockIn(current, input);
    await _sqlite.saveState(result.state);
    return (state: result.state, stockIn: result.stockIn);
  }

  Future<({ErpState state, StockAuditRecord audit})> recordStockAudit(
    ErpState current,
    RecordStockAuditInput input,
  ) async {
    final result = InventoryEngine.recordStockAudit(current, input);
    await _sqlite.saveState(result.state);
    return result;
  }

  Future<ErpState> syncFromCompanionServer() async {
    final remoteState = await _apiClient.fetchState();
    await _sqlite.saveState(remoteState);
    return remoteState;
  }
}
