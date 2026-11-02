import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/services/inventory_engine.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-06` — Redesigned Physical Ground-Stock Audit & Variance Reconciliation
class StockAuditScreen extends ConsumerStatefulWidget {
  const StockAuditScreen({super.key});

  @override
  ConsumerState<StockAuditScreen> createState() => _StockAuditScreenState();
}

class _StockAuditScreenState extends ConsumerState<StockAuditScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final categories = viewState.erpState.categories.isNotEmpty
        ? viewState.erpState.categories
        : InventoryEngine.createDefaultCategories();
    final allActiveMaterials = viewState.erpState.materials
        .where((m) => !m.isArchived)
        .toList();

    final materials = allActiveMaterials.where((m) {
      final matchesCat = _selectedCategory == 'all' ||
          m.effectiveCategoryCode == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.specs.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();

    final countedCount = viewState.draftAuditCounts.length;
    int varianceCount = 0;
    for (final m in allActiveMaterials) {
      if (viewState.draftAuditCounts.containsKey(m.id)) {
        final v = round2(viewState.draftAuditCounts[m.id]! - m.currentStock);
        if (v != 0) varianceCount++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        ErpSectionHeader(
          title: i18n.t('auditTitle'),
          count: materials.length,
          actionLabel:
              countedCount > 0 ? i18n.t('auditClearCounts') : null,
          onAction:
              countedCount > 0 ? controller.clearDraftAuditCounts : null,
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('auditSubtitle'),
          style: const TextStyle(
            fontSize: 12.5,
            color: ErpColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ErpColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        i18n.t('auditCountedItems'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '$countedCount / ${allActiveMaterials.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ErpColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ErpColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        i18n.t('auditVariancesDetected'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '$varianceCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: varianceCount > 0
                            ? ErpColors.statusWarning
                            : ErpColors.statusSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ErpSearchBar(
          hintText: i18n.t('searchMaterialsHint'),
          value: _searchQuery,
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AuditFilterChip(
                label: i18n.t('filterAllCategories'),
                isSelected: _selectedCategory == 'all',
                onTap: () => setState(() => _selectedCategory = 'all'),
              ),
              ...categories.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _AuditFilterChip(
                    label: i18n.categoryLabel(c.code, customName: c.name),
                    isSelected: _selectedCategory == c.code,
                    onTap: () => setState(() => _selectedCategory = c.code),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...materials.map((m) {
          final isCounted = viewState.draftAuditCounts.containsKey(m.id);
          final physical =
              viewState.draftAuditCounts[m.id] ?? m.currentStock;
          final variance = round2(physical - m.currentStock);
          final varianceCost = round2(variance * m.unitCost);
          final unitStr = i18n.unitLabel(m.unit.code);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ErpColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: variance == 0
                    ? (isCounted
                        ? ErpColors.primaryLight
                        : ErpColors.borderSubtle)
                    : (variance < 0
                        ? ErpColors.statusDanger.withValues(alpha: 0.45)
                        : ErpColors.statusSuccess.withValues(alpha: 0.45)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${i18n.t('auditExpected')}: ${formatQty(m.currentStock)} $unitStr',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isCounted
                            ? i18n.t('auditUntouched')
                            : '${i18n.t('auditVariance')}: ${variance > 0 ? '+' : ''}${formatQty(variance)} $unitStr${variance != 0 ? ' (${varianceCost >= 0 ? '+' : ''}${formatETB(varianceCost)})' : ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: !isCounted
                              ? ErpColors.textMuted
                              : (variance == 0
                                  ? ErpColors.statusSuccess
                                  : (variance < 0
                                      ? ErpColors.statusDanger
                                      : ErpColors.statusSuccess)),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: i18n.t('auditMatchExpected'),
                  onPressed: () =>
                      controller.updateDraftAuditCount(m.id, m.currentStock),
                  icon: Icon(
                    Icons.drag_handle_rounded,
                    size: 18,
                    color: isCounted && variance == 0
                        ? ErpColors.statusSuccess
                        : ErpColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey(
                      'audit_${m.id}_${m.currentStock}_${isCounted ? physical : 'uncounted'}',
                    ),
                    initialValue: formatQty(physical),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: i18n.t('auditPhysical'),
                    ),
                    onChanged: (v) {
                      if (v.trim().isEmpty) {
                        controller.updateDraftAuditCount(m.id, null);
                        return;
                      }
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed >= 0) {
                        controller.updateDraftAuditCount(m.id, parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        ErpInputField(
          label: i18n.t('auditNoteLabel'),
          prefixIcon: Icons.notes_rounded,
          onChanged: controller.updateDraftAuditNote,
        ),
        const SizedBox(height: 14),
        ErpButton(
          label: i18n.t('btnSubmitAudit'),
          icon: Icons.fact_check_outlined,
          variant: ErpButtonVariant.primary,
          isFullWidth: true,
          onPressed: allActiveMaterials.isEmpty
              ? null
              : () => controller.commitDraftAudit(),
        ),
      ],
    );
  }
}

class _AuditFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuditFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : ErpColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
