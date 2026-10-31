import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';

/// `SCR-02` & `SCR-03` — Material Catalog, Search/Filter & SKU-Free Registration/Edit
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final i18n = viewState.i18n;

    final filtered = viewState.erpState.materials.where((m) {
      final matchesCategory =
          _selectedCategory == 'all' || m.category.code == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.specs.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      children: [
        Container(
          color: ErpColors.surfaceCard,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: i18n.t('searchMaterialsHint'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ErpColors.accentTerracotta,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _showMaterialModal(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(i18n.t('btnRegisterMaterial')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryFilterButton(
                      label: i18n.t('filterAllCategories'),
                      isSelected: _selectedCategory == 'all',
                      onTap: () => setState(() => _selectedCategory = 'all'),
                    ),
                    ...MaterialCategory.values.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _CategoryFilterButton(
                          label: i18n.categoryLabel(c.code),
                          isSelected: _selectedCategory == c.code,
                          onTap: () =>
                              setState(() => _selectedCategory = c.code),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ErpColors.borderSubtle),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final m = filtered[idx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: m.isLowStock
                        ? ErpColors.statusWarning
                        : ErpColors.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ErpColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${i18n.categoryLabel(m.category.code)} • ${m.specs}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showMaterialModal(context, m),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(i18n.t('btnEditMetadata')),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: ErpColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MetricColumn(
                          label: i18n.t('lblStock'),
                          value:
                              '${formatQty(m.currentStock)} ${i18n.unitLabel(m.unit.code)}',
                          valueColor: m.isOutOfStock
                              ? ErpColors.statusDanger
                              : (m.isLowStock
                                  ? ErpColors.statusWarning
                                  : ErpColors.statusSuccess),
                        ),
                        _MetricColumn(
                          label: i18n.t('lblMin'),
                          value:
                              '${formatQty(m.minStockLevel)} ${i18n.unitLabel(m.unit.code)}',
                        ),
                        _MetricColumn(
                          label: i18n.t('lblCost'),
                          value: formatETB(m.unitCost),
                        ),
                        _MetricColumn(
                          label: i18n.t('lblPrice'),
                          value: formatETB(m.defaultSellingPrice),
                          valueColor: ErpColors.accentTerracotta,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMaterialModal(BuildContext context, MaterialItem? existing) {
    final i18n = ref.read(erpControllerProvider).i18n;
    final controller = ref.read(erpControllerProvider.notifier);

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

    MaterialCategory selectedCategory =
        existing?.category ?? MaterialCategory.rebar;
    MaterialUnit selectedUnit = existing?.unit ?? MaterialUnit.pcs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ErpColors.surfaceCard,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? i18n.t('btnRegisterMaterial')
                          : i18n.t('btnEditMetadata'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: i18n.t('fieldMaterialName'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<MaterialCategory>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: i18n.t('fieldCategory'),
                        border: const OutlineInputBorder(),
                      ),
                      items: MaterialCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(i18n.categoryLabel(c.code)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: specsCtrl,
                      decoration: InputDecoration(
                        labelText: i18n.t('fieldSpecs'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (existing == null) ...[
                      DropdownButtonFormField<MaterialUnit>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: i18n.t('fieldUnit'),
                          border: const OutlineInputBorder(),
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
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: i18n.t('fieldOpeningStock'),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: i18n.t('fieldUnitCost'),
                                border: const OutlineInputBorder(),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          i18n.t('immutableStockNotice'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minStockCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: i18n.t('fieldMinStock'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: i18n.t('fieldSellingPrice'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(i18n.t('btnCancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ErpColors.accentTerracotta,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            bool ok = false;
                            if (existing == null) {
                              ok = await controller.registerMaterial(
                                RegisterMaterialInput(
                                  name: nameCtrl.text,
                                  category: selectedCategory,
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
                                  category: selectedCategory,
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
                          child: Text(i18n.t('btnSave')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ErpColors.textPrimary
              : ErpColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? ErpColors.textPrimary
                : ErpColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ErpColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ErpColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? ErpColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
