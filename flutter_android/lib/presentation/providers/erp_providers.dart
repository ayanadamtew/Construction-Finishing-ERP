import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/erp_repository.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/inventory_engine.dart';
import '../../l10n/erp_localizations.dart';

/// Holds app state, active language (`en`, `am`, `om`), and draft form states
/// (`draftCart`, `draftAuditCounts`) so switching languages never loses user work (`FAIL-003`).
class ErpAppViewState {
  final ErpState erpState;
  final AppLanguage language;
  final int activeTabIndex;
  final List<SaleCartLineInput> draftCart;
  final String draftCustomerNote;
  final Map<String, double> draftAuditCounts;
  final String draftAuditNote;
  final bool isLoading;
  final bool companionSyncEnabled;
  final String? bannerMessage;
  final bool isBannerError;

  const ErpAppViewState({
    required this.erpState,
    this.language = AppLanguage.en,
    this.activeTabIndex = 0,
    this.draftCart = const [],
    this.draftCustomerNote = '',
    this.draftAuditCounts = const {},
    this.draftAuditNote = '',
    this.isLoading = false,
    this.companionSyncEnabled = false,
    this.bannerMessage,
    this.isBannerError = false,
  });

  ErpLocalizations get i18n => ErpLocalizations(language);

  ErpAppViewState copyWith({
    ErpState? erpState,
    AppLanguage? language,
    int? activeTabIndex,
    List<SaleCartLineInput>? draftCart,
    String? draftCustomerNote,
    Map<String, double>? draftAuditCounts,
    String? draftAuditNote,
    bool? isLoading,
    bool? companionSyncEnabled,
    String? bannerMessage,
    bool clearBanner = false,
    bool? isBannerError,
  }) {
    return ErpAppViewState(
      erpState: erpState ?? this.erpState,
      language: language ?? this.language,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      draftCart: draftCart ?? this.draftCart,
      draftCustomerNote: draftCustomerNote ?? this.draftCustomerNote,
      draftAuditCounts: draftAuditCounts ?? this.draftAuditCounts,
      draftAuditNote: draftAuditNote ?? this.draftAuditNote,
      isLoading: isLoading ?? this.isLoading,
      companionSyncEnabled: companionSyncEnabled ?? this.companionSyncEnabled,
      bannerMessage: clearBanner ? null : (bannerMessage ?? this.bannerMessage),
      isBannerError: isBannerError ?? this.isBannerError,
    );
  }
}

class ErpController extends StateNotifier<ErpAppViewState> {
  final ErpRepository _repository;

  ErpController(this._repository)
      : super(ErpAppViewState(erpState: InventoryEngine.createSeedState())) {
    _loadInitialDatabaseState();
  }

  Future<void> _loadInitialDatabaseState() async {
    final loaded = await _repository.initialize();
    state = state.copyWith(erpState: loaded);
  }

  void setLanguage(AppLanguage lang) {
    state = state.copyWith(language: lang, clearBanner: true);
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTabIndex: index, clearBanner: true);
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void addOrUpdateCartItem(SaleCartLineInput line) {
    final existingIdx =
        state.draftCart.indexWhere((c) => c.materialId == line.materialId);
    final updated = [...state.draftCart];
    if (existingIdx >= 0) {
      final prev = updated[existingIdx];
      updated[existingIdx] = SaleCartLineInput(
        materialId: line.materialId,
        quantity: prev.quantity + line.quantity,
        unitSellingPrice: line.unitSellingPrice,
      );
    } else {
      updated.add(line);
    }
    state = state.copyWith(draftCart: updated, clearBanner: true);
  }

  void removeCartItem(String materialId) {
    state = state.copyWith(
      draftCart:
          state.draftCart.where((c) => c.materialId != materialId).toList(),
      clearBanner: true,
    );
  }

  void updateDraftCustomerNote(String note) {
    state = state.copyWith(draftCustomerNote: note);
  }

  void updateDraftAuditCount(String materialId, double physicalCount) {
    final nextCounts = Map<String, double>.from(state.draftAuditCounts);
    nextCounts[materialId] = physicalCount;
    state = state.copyWith(draftAuditCounts: nextCounts, clearBanner: true);
  }

  void updateDraftAuditNote(String note) {
    state = state.copyWith(draftAuditNote: note);
  }

  Future<bool> registerMaterial(RegisterMaterialInput input) async {
    try {
      final nextErp =
          await _repository.registerMaterial(state.erpState, input);
      state = state.copyWith(
        erpState: nextErp,
        bannerMessage: 'Material "${input.name}" registered in SQLite ledger.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }

  Future<bool> updateMaterialMetadata(
    String materialId,
    UpdateMaterialInput input,
  ) async {
    try {
      final nextErp = await _repository.updateMaterialMetadata(
        state.erpState,
        materialId,
        input,
      );
      state = state.copyWith(
        erpState: nextErp,
        bannerMessage: 'Material metadata updated.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }

  Future<bool> completeDraftSale() async {
    try {
      final result = await _repository.recordSale(
        state.erpState,
        RecordSaleInput(
          items: state.draftCart,
          customerNote: state.draftCustomerNote,
        ),
      );
      state = state.copyWith(
        erpState: result.state,
        draftCart: const [],
        draftCustomerNote: '',
        bannerMessage:
            'Sale ${result.sale.id} completed and deducted from stock.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }

  Future<bool> recordStockIn(RecordStockInInput input) async {
    try {
      final result = await _repository.recordStockIn(state.erpState, input);
      state = state.copyWith(
        erpState: result.state,
        bannerMessage:
            'Stock-In recorded. Weighted-average unit cost updated to ETB ${result.stockIn.newUnitCost.toStringAsFixed(2)}.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }

  Future<bool> commitDraftAudit() async {
    try {
      final adjustments = state.erpState.materials.map((m) {
        final count = state.draftAuditCounts[m.id] ?? m.currentStock;
        return AuditAdjustmentInput(
          materialId: m.id,
          physicalCount: count,
        );
      }).toList();

      final result = await _repository.recordStockAudit(
        state.erpState,
        RecordStockAuditInput(
          adjustments: adjustments,
          auditNote: state.draftAuditNote,
        ),
      );

      state = state.copyWith(
        erpState: result.state,
        draftAuditCounts: const {},
        draftAuditNote: '',
        bannerMessage:
            'Ground-Stock Audit ${result.audit.id} committed to SQLite ledger.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }

  void toggleCompanionSync(bool enabled) {
    _repository.setCompanionSyncEnabled(enabled);
    state = state.copyWith(
      companionSyncEnabled: enabled,
      bannerMessage: enabled
          ? 'Companion Server write-through sync enabled.'
          : 'Offline-only SQLite mode active.',
      isBannerError: false,
    );
  }

  Future<bool> syncWithCompanionServer() async {
    state = state.copyWith(isLoading: true, clearBanner: true);
    try {
      final syncedState = await _repository.syncFromCompanionServer();
      state = state.copyWith(
        erpState: syncedState,
        isLoading: false,
        bannerMessage:
            'Synchronized ${syncedState.materials.length} materials from Companion Server.',
        isBannerError: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        bannerMessage: e.toString(),
        isBannerError: true,
      );
      return false;
    }
  }
}

final erpRepositoryProvider = Provider<ErpRepository>((ref) {
  return ErpRepository();
});

final erpControllerProvider =
    StateNotifierProvider<ErpController, ErpAppViewState>((ref) {
  final repo = ref.watch(erpRepositoryProvider);
  return ErpController(repo);
});
