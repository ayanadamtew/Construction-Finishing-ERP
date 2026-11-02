import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/inventory_engine.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'confirm_action_dialog.dart';

/// `SCR-02` & `SCR-03` — Redesigned Material Catalog, Search/Filter, Detail Sheet & Add/Edit Form
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final i18n = viewState.i18n;
    final erpState = viewState.erpState;
    final categories = erpState.categories.isNotEmpty
        ? erpState.categories
        : InventoryEngine.createDefaultCategories();

    final filtered = erpState.materials.where((m) {
      if (!_showArchived && m.isArchived) return false;
      final matchesCategory = _selectedCategory == 'all' ||
          m.effectiveCategoryCode == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.specs.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    final archivedCount =
        erpState.materials.where((m) => m.isArchived).length;

    return Scaffold(
      backgroundColor: ErpColors.bgPrimary,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ErpColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showMaterialModal(context, null),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          i18n.t('btnRegisterMaterial'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Search & Category Filter Header
          Container(
            color: ErpColors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErpSearchBar(
                  hintText: i18n.t('searchMaterialsHint'),
                  value: _searchQuery,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: i18n.t('filterAllCategories'),
                        isSelected: _selectedCategory == 'all',
                        onTap: () => setState(() => _selectedCategory = 'all'),
                      ),
                      ...categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _CategoryChip(
                            label:
                                i18n.categoryLabel(c.code, customName: c.name),
                            isSelected: _selectedCategory == c.code,
                            onTap: () =>
                                setState(() => _selectedCategory = c.code),
                          ),
                        ),
                      ),
                      if (archivedCount > 0) ...[
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: '${i18n.t('badgeArchived')} ($archivedCount)',
                          isSelected: _showArchived,
                          onTap: () =>
                              setState(() => _showArchived = !_showArchived),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ErpColors.borderSubtle),

          // Material List
          Expanded(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ErpEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: i18n.t('kpiMaterialsCount'),
                        actionLabel: i18n.t('btnRegisterMaterial'),
                        onAction: () => _showMaterialModal(context, null),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final m = filtered[idx];
                      final catObj = categories
                          .where((c) => c.code == m.effectiveCategoryCode)
                          .firstOrNull;
                      final catLabel = i18n.categoryLabel(
                        m.effectiveCategoryCode,
                        customName: catObj?.name,
                      );

                      return ErpMaterialListItem(
                        material: m,
                        categoryLabel: catLabel,
                        i18n: i18n,
                        onTap: () =>
                            _showMaterialDetailsSheet(context, m, catLabel),
                        onQuickAction: () => _showMaterialModal(context, m),
                        quickActionIcon: Icons.edit_outlined,
                        quickActionTooltip: i18n.t('btnEditMetadata'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Shows a clean Material Detail & Action Bottom Sheet so detailed fields and
  /// destructive/archive actions don't clutter the primary catalog list.
  void _showMaterialDetailsSheet(
    BuildContext context,
    MaterialItem m,
    String categoryLabel,
  ) {
    final viewState = ref.read(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final erpState = viewState.erpState;
    final isUsed = InventoryEngine.isMaterialUsed(erpState, m.id);
    final unitStr = i18n.unitLabel(m.unit.code);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return ErpBottomSheet(
          title: m.name,
          subtitle: m.specs.isNotEmpty
              ? '$categoryLabel • ${m.specs}'
              : categoryLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ErpSummaryCard(
                      label: i18n.t('lblStock'),
                      value: '${formatQty(m.currentStock)} $unitStr',
                      subtitle:
                          '${i18n.t('lblMin')}: ${formatQty(m.minStockLevel)} $unitStr',
                      icon: Icons.layers_outlined,
                      accentColor: m.isOutOfStock
                          ? ErpColors.statusDanger
                          : (m.isLowStock
                              ? ErpColors.statusWarning
                              : ErpColors.statusSuccess),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ErpSummaryCard(
                      label: i18n.t('lblPrice'),
                      value: formatETB(m.defaultSellingPrice),
                      subtitle:
                          '${i18n.t('lblCost')}: ${formatETB(m.unitCost)}',
                      icon: Icons.sell_outlined,
                      accentColor: ErpColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ErpButton(
                      label: i18n.t('btnEditMetadata'),
                      icon: Icons.edit_outlined,
                      variant: ErpButtonVariant.primary,
                      isFullWidth: true,
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        _showMaterialModal(context, m);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (m.isArchived)
                    Expanded(
                      child: ErpButton(
                        label: i18n.t('btnRestore'),
                        icon: Icons.restore_outlined,
                        variant: ErpButtonVariant.secondary,
                        isFullWidth: true,
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();
                          await controller.setMaterialArchivedStatus(
                            m.id,
                            false,
                          );
                        },
                      ),
                    )
                  else if (isUsed)
                    Expanded(
                      child: ErpButton(
                        label: i18n.t('btnArchive'),
                        icon: Icons.archive_outlined,
                        variant: ErpButtonVariant.secondary,
                        isFullWidth: true,
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();
                          final res = await ConfirmActionDialog.show(
                            context,
                            title: i18n.t('confirmArchiveTitle'),
                            recordName: m.name,
                            description:
                                'This material has historical ledger transactions and cannot be permanently deleted. Archiving hides it from active POS and Stock-In lists while preserving ledger history.',
                            confirmLabel: i18n.t('btnArchive'),
                            confirmColor: ErpColors.statusWarning,
                            i18n: i18n,
                          );
                          if (res != null && res.confirmed) {
                            await controller.setMaterialArchivedStatus(
                              m.id,
                              true,
                            );
                          }
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: ErpButton(
                        label: i18n.t('btnDelete'),
                        icon: Icons.delete_outline,
                        variant: ErpButtonVariant.danger,
                        isFullWidth: true,
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();
                          final res = await ConfirmActionDialog.show(
                            context,
                            title: i18n.t('confirmDeleteTitle'),
                            recordName: m.name,
                            description:
                                'This material has no historical transactions. Permanently delete it from the SQLite catalog?',
                            confirmLabel: i18n.t('btnDelete'),
                            confirmColor: ErpColors.statusDanger,
                            i18n: i18n,
                          );
                          if (res != null && res.confirmed) {
                            await controller.deleteMaterial(m.id);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaterialModal(BuildContext context, MaterialItem? existing) {
    final viewState = ref.read(erpControllerProvider);
    final i18n = viewState.i18n;
    final controller = ref.read(erpControllerProvider.notifier);
    final categories = viewState.erpState.categories.isNotEmpty
        ? viewState.erpState.categories
        : InventoryEngine.createDefaultCategories();

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final specsCtrl = TextEditingController(text: existing?.specs ?? '');
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.currentStock.toString() : '0',
    );
    final minStockCtrl = TextEditingController(
      text: existing != null ? existing.minStockLevel.toString() : '10',
    );
    final costCtrl = TextEditingController(
      text: existing != null ? existing.unitCost.toString() : '0',
    );
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.defaultSellingPrice.toString() : '0',
    );

    String selectedCategoryCode =
        existing?.effectiveCategoryCode ?? categories.first.code;
    if (!categories.any((c) => c.code == selectedCategoryCode)) {
      selectedCategoryCode = categories.first.code;
    }
    MaterialUnit selectedUnit = existing?.unit ?? MaterialUnit.pcs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ErpBottomSheet(
              title: existing == null
                  ? i18n.t('btnRegisterMaterial')
                  : i18n.t('btnEditMetadata'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErpInputField(
                    controller: nameCtrl,
                    label: i18n.t('fieldMaterialName'),
                    prefixIcon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryCode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: i18n.t('fieldCategory'),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              i18n.categoryLabel(c.code, customName: c.name),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => selectedCategoryCode = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ErpInputField(
                    controller: specsCtrl,
                    label: i18n.t('fieldSpecs'),
                    prefixIcon: Icons.straighten_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (existing == null) ...[
                    DropdownButtonFormField<MaterialUnit>(
                      value: selectedUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('fieldUnit'),
                      ),
                      items: MaterialUnit.values
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(i18n.unitLabel(u.code)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedUnit = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ErpInputField(
                            controller: stockCtrl,
                            label: i18n.t('fieldOpeningStock'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ErpInputField(
                            controller: costCtrl,
                            label: i18n.t('fieldUnitCost'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ErpColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        i18n.t('immutableStockNotice'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ErpInputField(
                          controller: minStockCtrl,
                          label: i18n.t('fieldMinStock'),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ErpInputField(
                          controller: priceCtrl,
                          label: i18n.t('fieldSellingPrice'),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ErpButton(
                          label: i18n.t('btnCancel'),
                          variant: ErpButtonVariant.secondary,
                          isFullWidth: true,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ErpButton(
                          label: i18n.t('btnSave'),
                          icon: Icons.check_rounded,
                          variant: ErpButtonVariant.primary,
                          isFullWidth: true,
                          onPressed: () async {
                            bool ok = false;
                            if (existing == null) {
                              ok = await controller.registerMaterial(
                                RegisterMaterialInput(
                                  name: nameCtrl.text,
                                  category: MaterialCategory.fromCode(
                                    selectedCategoryCode,
                                  ),
                                  categoryCode: selectedCategoryCode,
                                  specs: specsCtrl.text,
                                  unit: selectedUnit,
                                  currentStock:
                                      double.tryParse(stockCtrl.text) ?? 0,
                                  minStockLevel:
                                      double.tryParse(minStockCtrl.text) ?? 0,
                                  unitCost:
                                      double.tryParse(costCtrl.text) ?? 0,
                                  defaultSellingPrice:
                                      double.tryParse(priceCtrl.text) ?? 0,
                                ),
                              );
                            } else {
                              ok = await controller.updateMaterialMetadata(
                                existing.id,
                                UpdateMaterialInput(
                                  name: nameCtrl.text,
                                  category: MaterialCategory.fromCode(
                                    selectedCategoryCode,
                                  ),
                                  categoryCode: selectedCategoryCode,
                                  specs: specsCtrl.text,
                                  minStockLevel:
                                      double.tryParse(minStockCtrl.text) ?? 0,
                                  defaultSellingPrice:
                                      double.tryParse(priceCtrl.text) ?? 0,
                                ),
                              );
                            }
                            if (ok && ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ErpColors.primary : ErpColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? ErpColors.primary : ErpColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : ErpColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
