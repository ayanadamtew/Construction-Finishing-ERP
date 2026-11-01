import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';

/// `SCR-06` — Physical Ground-Stock Audit & Variance Reconciliation (`FR-015`–`FR-017`)
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          i18n.t('auditTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ErpColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('auditSubtitle'),
          style: const TextStyle(
            fontSize: 13,
            color: ErpColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...materials.map((m) {
          final physical =
              viewState.draftAuditCounts[m.id] ?? m.currentStock;
          final variance = round2(physical - m.currentStock);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ErpColors.surfaceCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: variance == 0
                    ? ErpColors.borderSubtle
                    : (variance < 0
                        ? ErpColors.statusDanger
                        : ErpColors.statusSuccess),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${i18n.t('auditExpected')}: ${formatQty(m.currentStock)} ${i18n.unitLabel(m.unit.code)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${i18n.t('auditVariance')}: ${variance > 0 ? '+' : ''}${formatQty(variance)} ${i18n.unitLabel(m.unit.code)}',
                        style: TextStyle(
                          fontSize: 12,
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
                    initialValue: formatQty(physical),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: i18n.t('auditPhysical'),
                      isDense: true,
                      border: const OutlineInputBorder(),
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
        TextField(
          onChanged: controller.updateDraftAuditNote,
          decoration: InputDecoration(
            labelText: i18n.t('auditNoteLabel'),
            filled: true,
            fillColor: ErpColors.surfaceCard,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: ErpColors.accentTerracotta,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => controller.commitDraftAudit(),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(
            i18n.t('btnSubmitAudit'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
