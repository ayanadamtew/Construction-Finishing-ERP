import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/erp_repository.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/auth_engine.dart';
import '../../domain/services/inventory_engine.dart';
import '../../l10n/erp_localizations.dart';

/// Holds app state, authenticated user, user list, active language (`en`, `am`, `om`),
/// and draft form states (`draftCart`, `draftAuditCounts`) so switching languages never loses user work (`FAIL-003`).
class ErpAppViewState {
  final ErpState erpState;
  final PublicUser? currentUser;
  final List<UserAccount> users;
  final AppLanguage language;
  final int activeTabIndex;
  final int inventorySubTab;
  final int moreSubTab;
  final String? selectedStockInMaterialId;
  final List<SaleCartLineInput> draftCart;
  final String draftCustomerNote;
  final SaleTransaction? lastCompletedSale;
  final Map<String, double> draftAuditCounts;
  final String draftAuditNote;
  final bool isLoading;
  final bool companionSyncEnabled;
  final String? bannerMessage;
  final bool isBannerError;

  const ErpAppViewState({
    required this.erpState,
    this.currentUser,
    this.users = const [],
    this.language = AppLanguage.en,
    this.activeTabIndex = 0,
    this.inventorySubTab = 0,
    this.moreSubTab = 0,
    this.selectedStockInMaterialId,
    this.draftCart = const [],
    this.draftCustomerNote = '',
    this.lastCompletedSale,
    this.draftAuditCounts = const {},
    this.draftAuditNote = '',
    this.isLoading = false,
    this.companionSyncEnabled = false,
    this.bannerMessage,
    this.isBannerError = false,
  });

  ErpLocalizations get i18n => ErpLocalizations(language);

  List<PublicUser> get publicUsers =>
      users.map(AuthEngine.toPublicUser).toList();

  ErpAppViewState copyWith({
    ErpState? erpState,
    PublicUser? currentUser,
    bool clearCurrentUser = false,
    List<UserAccount>? users,
    AppLanguage? language,
    int? activeTabIndex,
    int? inventorySubTab,
    int? moreSubTab,
    String? selectedStockInMaterialId,
    bool clearSelectedStockInMaterial = false,
    List<SaleCartLineInput>? draftCart,
    String? draftCustomerNote,
    SaleTransaction? lastCompletedSale,
    bool clearLastCompletedSale = false,
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
      currentUser:
          clearCurrentUser ? null : (currentUser ?? this.currentUser),
      users: users ?? this.users,
      language: language ?? this.language,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      inventorySubTab: inventorySubTab ?? this.inventorySubTab,
      moreSubTab: moreSubTab ?? this.moreSubTab,
      selectedStockInMaterialId: clearSelectedStockInMaterial
          ? null
          : (selectedStockInMaterialId ?? this.selectedStockInMaterialId),
      draftCart: draftCart ?? this.draftCart,
      draftCustomerNote: draftCustomerNote ?? this.draftCustomerNote,
      lastCompletedSale: clearLastCompletedSale
          ? null
          : (lastCompletedSale ?? this.lastCompletedSale),
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
      : super(
          ErpAppViewState(
            erpState: _repository.seedDemoData
                ? InventoryEngine.createSeedState()
                : InventoryEngine.createProductionState(),
            users: <UserAccount>[AuthEngine.createDefaultAdminUser()],
          ),
        ) {
    _loadInitialDatabaseState();
  }

  Future<void> _loadInitialDatabaseState() async {
    final loaded = await _repository.initialize();
    state = state.copyWith(
      erpState: loaded.erpState,
      users: loaded.users,
      currentUser: loaded.activeUser,
    );
  }

  void setLanguage(AppLanguage lang) {
    state = state.copyWith(language: lang, clearBanner: true);
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTabIndex: index, clearBanner: true);
  }

  void openInventorySubTab(int subTab) {
    state = state.copyWith(
      activeTabIndex: 3,
      inventorySubTab: subTab,
      clearBanner: true,
    );
  }

  void openStockInForMaterial(String materialId) {
    state = state.copyWith(
      activeTabIndex: 3,
      inventorySubTab: 0,
      selectedStockInMaterialId: materialId,
      clearBanner: true,
    );
  }

  void selectStockInMaterial(String materialId) {
    state = state.copyWith(
      selectedStockInMaterialId: materialId,
      clearBanner: true,
    );
  }

  void sellMaterialInPos(MaterialItem material) {
    if (material.currentStock > 0) {
      addOrUpdateCartItem(
        SaleCartLineInput(
          materialId: material.id,
          quantity: material.currentStock >= 1 ? 1 : material.currentStock,
          unitSellingPrice: material.defaultSellingPrice,
        ),
      );
    }
    state = state.copyWith(
      activeTabIndex: 2,
      clearBanner: true,
    );
  }

  void openMoreSubTab(int subTab) {
    state = state.copyWith(
      activeTabIndex: 4,
      moreSubTab: subTab,
      clearBanner: true,
    );
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }

  void dismissLastCompletedSale() {
    state = state.copyWith(clearLastCompletedSale: true);
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      final res = await _repository.login(
        currentUsers: state.users,
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      state = state.copyWith(
        currentUser: res.user,
        users: res.users,
        clearBanner: true,
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

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      clearCurrentUser: true,
      clearLastCompletedSale: true,
      activeTabIndex: 0,
      clearBanner: true,
    );
  }

  Future<bool> createUser(CreateUserInput input) async {
    final actor = state.currentUser;
    if (actor == null) return false;
    try {
      final res = await _repository.createUser(
        currentUsers: state.users,
        actor: actor,
        input: input,
      );
      state = state.copyWith(
        users: res.users,
        bannerMessage: 'User "${res.created.username}" created.',
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

  Future<bool> toggleUserStatus(String targetUserId, bool isActive) async {
    final actor = state.currentUser;
    if (actor == null) return false;
    try {
      final updated = await _repository.toggleUserStatus(
        currentUsers: state.users,
        actor: actor,
        targetUserId: targetUserId,
        isActive: isActive,
      );
      state = state.copyWith(
        users: updated,
        bannerMessage:
            isActive ? 'User account activated.' : 'User account deactivated.',
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

  Future<bool> deleteUser(String targetUserId) async {
    final actor = state.currentUser;
    if (actor == null) return false;
    try {
      final updated = await _repository.deleteUser(
        currentUsers: state.users,
        actor: actor,
        targetUserId: targetUserId,
      );
      state = state.copyWith(
        users: updated,
        bannerMessage: 'User account permanently deleted.',
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

  void setCartItemQuantity(String materialId, double quantity) {
    if (quantity <= 0) {
      removeCartItem(materialId);
      return;
    }
    final updated = state.draftCart.map((c) {
      if (c.materialId != materialId) return c;
      return SaleCartLineInput(
        materialId: c.materialId,
        quantity: quantity,
        unitSellingPrice: c.unitSellingPrice,
      );
    }).toList();
    state = state.copyWith(draftCart: updated, clearBanner: true);
  }

  void setCartItemPrice(String materialId, double unitSellingPrice) {
    if (unitSellingPrice < 0) return;
    final updated = state.draftCart.map((c) {
      if (c.materialId != materialId) return c;
      return SaleCartLineInput(
        materialId: c.materialId,
        quantity: c.quantity,
        unitSellingPrice: unitSellingPrice,
      );
    }).toList();
    state = state.copyWith(draftCart: updated, clearBanner: true);
  }

  void removeCartItem(String materialId) {
    state = state.copyWith(
      draftCart:
          state.draftCart.where((c) => c.materialId != materialId).toList(),
      clearBanner: true,
    );
  }

  void clearDraftCart() {
    state = state.copyWith(
      draftCart: const [],
      draftCustomerNote: '',
      clearBanner: true,
    );
  }

  void updateDraftCustomerNote(String note) {
    state = state.copyWith(draftCustomerNote: note);
  }

  void updateDraftAuditCount(String materialId, double? physicalCount) {
    final nextCounts = Map<String, double>.from(state.draftAuditCounts);
    if (physicalCount == null) {
      nextCounts.remove(materialId);
    } else {
      nextCounts[materialId] = physicalCount;
    }
    state = state.copyWith(draftAuditCounts: nextCounts, clearBanner: true);
  }

  void clearDraftAuditCounts() {
    state = state.copyWith(
      draftAuditCounts: const {},
      draftAuditNote: '',
      clearBanner: true,
    );
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

  Future<bool> deleteMaterial(String materialId) async {
    try {
      final result =
          await _repository.deleteMaterial(state.erpState, materialId);
      state = state.copyWith(
        erpState: result.state,
        draftCart:
            state.draftCart.where((c) => c.materialId != materialId).toList(),
        bannerMessage:
            'Unused material "${result.deletedMaterial.name}" permanently deleted.',
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

  Future<bool> setMaterialArchivedStatus(
    String materialId,
    bool isArchived,
  ) async {
    try {
      final actor = state.currentUser?.username ?? 'admin';
      final result = await _repository.setMaterialArchivedStatus(
        state.erpState,
        materialId,
        isArchived: isArchived,
        actorUsername: actor,
      );
      state = state.copyWith(
        erpState: result.state,
        draftCart: isArchived
            ? state.draftCart.where((c) => c.materialId != materialId).toList()
            : state.draftCart,
        bannerMessage: isArchived
            ? 'Material "${result.material.name}" archived.'
            : 'Material "${result.material.name}" restored to active catalog.',
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

  Future<bool> createCategory(CreateCategoryInput input) async {
    try {
      final actor = state.currentUser?.username ?? 'admin';
      final result = await _repository.createCategory(
        state.erpState,
        input,
        actorUsername: actor,
      );
      state = state.copyWith(
        erpState: result.state,
        bannerMessage: 'Category "${result.category.name}" created.',
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

  Future<bool> deleteCategory(String categoryIdOrCode) async {
    try {
      final result =
          await _repository.deleteCategory(state.erpState, categoryIdOrCode);
      state = state.copyWith(
        erpState: result.state,
        bannerMessage:
            'Category "${result.deletedCategory.name}" deleted.',
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
        lastCompletedSale: result.sale,
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

  Future<bool> reverseSale(String saleId, String reason) async {
    try {
      final actor = state.currentUser?.username ?? 'admin';
      final result = await _repository.reverseSale(
        state.erpState,
        saleId,
        reason: reason,
        actorUsername: actor,
      );
      final clearReceipt = state.lastCompletedSale?.id == saleId;
      state = state.copyWith(
        erpState: result.state,
        clearLastCompletedSale: clearReceipt,
        bannerMessage:
            'Sale ${result.sale.id} reversed and inventory quantities restored.',
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

  Future<bool> reverseStockIn(String stockInId, String reason) async {
    try {
      final actor = state.currentUser?.username ?? 'admin';
      final result = await _repository.reverseStockIn(
        state.erpState,
        stockInId,
        reason: reason,
        actorUsername: actor,
      );
      state = state.copyWith(
        erpState: result.state,
        bannerMessage:
            'Stock-In ${result.stockIn.id} reversed and previous stock/unit cost restored.',
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
      final activeMaterials =
          state.erpState.materials.where((m) => !m.isArchived).toList();
      final adjustments = state.draftAuditCounts.isNotEmpty
          ? state.draftAuditCounts.entries
              .where((e) => activeMaterials.any((m) => m.id == e.key))
              .map(
                (e) => AuditAdjustmentInput(
                  materialId: e.key,
                  physicalCount: e.value,
                ),
              )
              .toList()
          : activeMaterials
              .map(
                (m) => AuditAdjustmentInput(
                  materialId: m.id,
                  physicalCount: m.currentStock,
                ),
              )
              .toList();

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

  Future<bool> reverseAudit(String auditId, String reason) async {
    try {
      final actor = state.currentUser?.username ?? 'admin';
      final result = await _repository.reverseAudit(
        state.erpState,
        auditId,
        reason: reason,
        actorUsername: actor,
      );
      state = state.copyWith(
        erpState: result.state,
        bannerMessage:
            'Stock Audit ${result.audit.id} reversed and variance adjustments undone.',
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
