import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';
import 'confirm_action_dialog.dart';

/// `SCR-07` — Immutable Transaction History Ledger (Sales, Stock-In, Audits) with Authorized Reversal Workflow
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final erp = viewState.erpState;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: ErpColors.surfaceCard,
            child: TabBar(
              labelColor: ErpColors.accentTerracotta,
              unselectedLabelColor: ErpColors.textSecondary,
              indicatorColor: ErpColors.accentTerracotta,
              tabs: [
                Tab(text: '${i18n.t('tabSales')} (${erp.sales.length})'),
                Tab(text: '${i18n.t('tabStockIn')} (${erp.stockIns.length})'),
                Tab(text: '${i18n.t('tabAudits')} (${erp.audits.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Sales Receipts Tab
                ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: erp.sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final sale = erp.sales[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sale.isReversed
                            ? ErpColors.surfaceElevated
                            : ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: sale.isReversed
                              ? ErpColors.statusDanger
                              : ErpColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sale.id.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      decoration: sale.isReversed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (sale.isReversed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ErpColors.statusDangerBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        i18n.t('badgeReversed'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: ErpColors.statusDanger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatETB(sale.totalAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: sale.isReversed
                                          ? ErpColors.textMuted
                                          : ErpColors.accentTerracotta,
                                      decoration: sale.isReversed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (!sale.isReversed) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: ErpColors.statusDanger,
                                        side: const BorderSide(
                                          color: ErpColors.statusDanger,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      onPressed: () async {
                                        final res =
                                            await ConfirmActionDialog.show(
                                          context,
                                          title: i18n.t('confirmReverseTitle'),
                                          recordName:
                                              '${sale.id.toUpperCase()} (${formatETB(sale.totalAmount)})',
                                          description:
                                              'Reversing this sale restores all sold material quantities to stock while preserving the original receipt in the audit trail.',
                                          confirmLabel: i18n.t('btnReverse'),
                                          requireReason: true,
                                          i18n: i18n,
                                        );
                                        if (res != null && res.confirmed) {
                                          await controller.reverseSale(
                                            sale.id,
                                            res.reason,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.undo, size: 14),
                                      label: Text(
                                        i18n.t('btnReverse'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (sale.customerNote.isNotEmpty)
                            Text(
                              sale.customerNote,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpColors.textSecondary,
                              ),
                            ),
                          if (sale.isReversed) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${i18n.t('reversedByLabel')}: ${sale.reversedBy ?? 'admin'} • ${sale.reversalReason ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ],
                          const Divider(
                            height: 16,
                            color: ErpColors.borderSubtle,
                          ),
                          ...sale.items.map(
                            (line) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${line.materialName} (${formatQty(line.quantity)} ${i18n.unitLabel(line.unit.code)})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    formatETB(line.lineTotal),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Stock-In Deliveries Tab
                ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: erp.stockIns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final stin = erp.stockIns[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: stin.isReversed
                            ? ErpColors.surfaceElevated
                            : ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: stin.isReversed
                              ? ErpColors.statusDanger
                              : ErpColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        stin.materialName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          decoration: stin.isReversed
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (stin.isReversed) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ErpColors.statusDangerBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          i18n.t('badgeReversed'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: ErpColors.statusDanger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!stin.isReversed)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ErpColors.statusDanger,
                                    side: const BorderSide(
                                      color: ErpColors.statusDanger,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  onPressed: () async {
                                    final res = await ConfirmActionDialog.show(
                                      context,
                                      title: i18n.t('confirmReverseTitle'),
                                      recordName:
                                          '${stin.id.toUpperCase()} — ${stin.materialName} (+${formatQty(stin.quantityAdded)})',
                                      description:
                                          'Reversing this Stock-In deducts the added quantity and restores the previous weighted-average unit cost.',
                                      confirmLabel: i18n.t('btnReverse'),
                                      requireReason: true,
                                      i18n: i18n,
                                    );
                                    if (res != null && res.confirmed) {
                                      await controller.reverseStockIn(
                                        stin.id,
                                        res.reason,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.undo, size: 14),
                                  label: Text(
                                    i18n.t('btnReverse'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${formatQty(stin.quantityAdded)} ${i18n.unitLabel(stin.unit.code)} @ ${formatETB(stin.unitPurchaseCost)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: stin.isReversed
                                  ? ErpColors.textMuted
                                  : ErpColors.statusSuccess,
                            ),
                          ),
                          Text(
                            'Avg Cost: ${formatETB(stin.previousUnitCost)} → ${formatETB(stin.newUnitCost)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpColors.textSecondary,
                            ),
                          ),
                          if (stin.supplierNote.isNotEmpty)
                            Text(
                              stin.supplierNote,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpColors.textMuted,
                              ),
                            ),
                          if (stin.isReversed) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${i18n.t('reversedByLabel')}: ${stin.reversedBy ?? 'admin'} • ${stin.reversalReason ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                // Stock Audits Tab
                ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: erp.audits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final aud = erp.audits[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: aud.isReversed
                            ? ErpColors.surfaceElevated
                            : ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: aud.isReversed
                              ? ErpColors.statusDanger
                              : ErpColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    aud.id.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      decoration: aud.isReversed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (aud.isReversed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ErpColors.statusDangerBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        i18n.t('badgeReversed'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: ErpColors.statusDanger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!aud.isReversed)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ErpColors.statusDanger,
                                    side: const BorderSide(
                                      color: ErpColors.statusDanger,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  onPressed: () async {
                                    final res = await ConfirmActionDialog.show(
                                      context,
                                      title: i18n.t('confirmReverseTitle'),
                                      recordName: aud.id.toUpperCase(),
                                      description:
                                          'Reversing this Stock Audit undoes all variance adjustments applied to warehouse materials.',
                                      confirmLabel: i18n.t('btnReverse'),
                                      requireReason: true,
                                      i18n: i18n,
                                    );
                                    if (res != null && res.confirmed) {
                                      await controller.reverseAudit(
                                        aud.id,
                                        res.reason,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.undo, size: 14),
                                  label: Text(
                                    i18n.t('btnReverse'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (aud.auditNote.isNotEmpty)
                            Text(
                              aud.auditNote,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpColors.textSecondary,
                              ),
                            ),
                          if (aud.isReversed) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${i18n.t('reversedByLabel')}: ${aud.reversedBy ?? 'admin'} • ${aud.reversalReason ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ],
                          const Divider(
                            height: 14,
                            color: ErpColors.borderSubtle,
                          ),
                          ...aud.adjustments.map(
                            (adj) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      adj.materialName,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '${formatQty(adj.expectedStock)} → ${formatQty(adj.physicalCount)} (${adj.variance >= 0 ? '+' : ''}${formatQty(adj.variance)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
