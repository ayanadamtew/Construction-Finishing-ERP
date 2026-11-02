import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-06` — Redesigned Physical Ground-Stock Audit & Variance Reconciliation
class StockAuditScreen extends ConsumerWidget {
  const StockAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final materials = viewState.erpState.materials
        .where((m) => !m.isArchived)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        ErpSectionHeader(
          title: i18n.t('auditTitle'),
          count: materials.length,
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('auditSubtitle'),
          style: const TextStyle(
            fontSize: 12.5,
            color: ErpColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...materials.map((m) {
          final physical =
              viewState.draftAuditCounts[m.id] ?? m.currentStock;
          final variance = round2(physical - m.currentStock);
          final unitStr = i18n.unitLabel(m.unit.code);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ErpColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: variance == 0
                    ? ErpColors.borderSubtle
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
                        '${i18n.t('auditVariance')}: ${variance > 0 ? '+' : ''}${formatQty(variance)} $unitStr',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: variance == 0
                              ? ErpColors.textMuted
                              : (variance < 0
                                  ? ErpColors.statusDanger
                                  : ErpColors.statusSuccess),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('audit_${m.id}_${m.currentStock}'),
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
          onPressed: () => controller.commitDraftAudit(),
        ),
      ],
    );
  }
}
