import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'confirm_action_dialog.dart';

/// `SCR-07` — Redesigned Immutable Transaction History Ledger (All, Sales, Stock-In, Audits) with Search & Reversals
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final erp = viewState.erpState;
    final q = _searchQuery.trim().toLowerCase();

    final filteredSales = erp.sales.where((s) {
      if (q.isEmpty) return true;
      return s.id.toLowerCase().contains(q) ||
          s.customerNote.toLowerCase().contains(q) ||
          s.items.any((i) => i.materialName.toLowerCase().contains(q));
    }).toList();

    final filteredStockIns = erp.stockIns.where((s) {
      if (q.isEmpty) return true;
      return s.id.toLowerCase().contains(q) ||
          s.materialName.toLowerCase().contains(q) ||
          s.supplierNote.toLowerCase().contains(q);
    }).toList();

    final filteredAudits = erp.audits.where((a) {
      if (q.isEmpty) return true;
      return a.id.toLowerCase().contains(q) ||
          a.auditNote.toLowerCase().contains(q) ||
          a.adjustments.any((adj) => adj.materialName.toLowerCase().contains(q));
    }).toList();

    final totalAllCount =
        filteredSales.length + filteredStockIns.length + filteredAudits.length;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: ErpColors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: ErpSearchBar(
              hintText: i18n.t('searchLedgerHint'),
              value: _searchQuery,
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Container(
            color: ErpColors.surfaceCard,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: ErpColors.primaryDark,
              unselectedLabelColor: ErpColors.textSecondary,
              indicatorColor: ErpColors.primary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: '${i18n.t('tabAll')} ($totalAllCount)'),
                Tab(text: '${i18n.t('tabSales')} (${filteredSales.length})'),
                Tab(
                  text: '${i18n.t('tabStockIn')} (${filteredStockIns.length})',
                ),
                Tab(text: '${i18n.t('tabAudits')} (${filteredAudits.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 0. Unified "All" Chronological Feed Tab
                totalAllCount == 0
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: ErpEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: i18n.t('noRecentSales'),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          ...filteredSales.map(
                            (sale) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ErpTransactionListItem(
                                title: sale.customerNote.isNotEmpty
                                    ? sale.customerNote
                                    : sale.id.toUpperCase(),
                                subtitle:
                                    '${i18n.t('tabSales')} • ${sale.id.toUpperCase()} • ${sale.createdAt.split('T').first}',
                                amountText: formatETB(sale.totalAmount),
                                secondaryAmountText:
                                    '+${formatETB(sale.totalProfit)} ${i18n.t('profitLabel')}',
                                isReversed: sale.isReversed,
                                statusBadgeText: sale.isReversed
                                    ? i18n.t('badgeReversed')
                                    : null,
                              ),
                            ),
                          ),
                          ...filteredStockIns.map(
                            (stin) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ErpTransactionListItem(
                                title: stin.materialName,
                                subtitle:
                                    '${i18n.t('tabStockIn')} • ${stin.id.toUpperCase()} • ${stin.createdAt.split('T').first}',
                                amountText:
                                    '+${formatQty(stin.quantityAdded)} ${i18n.unitLabel(stin.unit.code)}',
                                secondaryAmountText:
                                    formatETB(stin.totalPurchaseCost),
                                isReversed: stin.isReversed,
                                statusBadgeText: stin.isReversed
                                    ? i18n.t('badgeReversed')
                                    : null,
                              ),
                            ),
                          ),
                          ...filteredAudits.map(
                            (aud) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ErpTransactionListItem(
                                title: aud.auditNote.isNotEmpty
                                    ? aud.auditNote
                                    : aud.id.toUpperCase(),
                                subtitle:
                                    '${i18n.t('tabAudits')} • ${aud.id.toUpperCase()} • ${aud.createdAt.split('T').first}',
                                amountText:
                                    '${aud.adjustments.length} ${i18n.t('itemsCount')}',
                                isReversed: aud.isReversed,
                                statusBadgeText: aud.isReversed
                                    ? i18n.t('badgeReversed')
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                // 1. Sales Receipts Tab
                filteredSales.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: ErpEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: i18n.t('noRecentSales'),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredSales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final sale = filteredSales[idx];
                          final dateStr = sale.createdAt.split('T').first;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: sale.isReversed
                                  ? ErpColors.surfaceElevated
                                  : ErpColors.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sale.isReversed
                                    ? ErpColors.statusDanger
                                        .withValues(alpha: 0.35)
                                    : ErpColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              sale.customerNote.isNotEmpty
                                                  ? sale.customerNote
                                                  : sale.id.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: sale.isReversed
                                                    ? ErpColors.textMuted
                                                    : ErpColors.textPrimary,
                                                decoration: sale.isReversed
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (sale.isReversed) ...[
                                            const SizedBox(width: 6),
                                            ErpStatusLabel(
                                              text: i18n.t('badgeReversed'),
                                              textColor: ErpColors.statusDanger,
                                              backgroundColor:
                                                  ErpColors.statusDangerBg,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatETB(sale.totalAmount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: sale.isReversed
                                            ? ErpColors.textMuted
                                            : ErpColors.primaryDark,
                                        decoration: sale.isReversed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${sale.id.toUpperCase()} • $dateStr',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: ErpColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (!sale.isReversed)
                                      ErpButton(
                                        label: i18n.t('btnReverse'),
                                        icon: Icons.undo_rounded,
                                        variant: ErpButtonVariant.danger,
                                        isCompact: true,
                                        onPressed: () async {
                                          final res =
                                              await ConfirmActionDialog.show(
                                            context,
                                            title:
                                                i18n.t('confirmReverseTitle'),
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
                                      ),
                                  ],
                                ),
                                if (sale.isReversed) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${i18n.t('reversedByLabel')}: ${sale.reversedBy ?? 'admin'} • ${sale.reversalReason ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${line.materialName} (${formatQty(line.quantity)} ${i18n.unitLabel(line.unit.code)})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: ErpColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formatETB(line.lineTotal),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ErpColors.textPrimary,
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

                // 2. Stock-In Deliveries Tab
                filteredStockIns.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: ErpEmptyState(
                            icon: Icons.south_west_rounded,
                            title: i18n.t('tabStockIn'),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredStockIns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final stin = filteredStockIns[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: stin.isReversed
                                  ? ErpColors.surfaceElevated
                                  : ErpColors.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: stin.isReversed
                                    ? ErpColors.statusDanger
                                        .withValues(alpha: 0.35)
                                    : ErpColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              stin.materialName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                decoration: stin.isReversed
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (stin.isReversed) ...[
                                            const SizedBox(width: 6),
                                            ErpStatusLabel(
                                              text: i18n.t('badgeReversed'),
                                              textColor: ErpColors.statusDanger,
                                              backgroundColor:
                                                  ErpColors.statusDangerBg,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!stin.isReversed)
                                      ErpButton(
                                        label: i18n.t('btnReverse'),
                                        icon: Icons.undo_rounded,
                                        variant: ErpButtonVariant.danger,
                                        isCompact: true,
                                        onPressed: () async {
                                          final res =
                                              await ConfirmActionDialog.show(
                                            context,
                                            title:
                                                i18n.t('confirmReverseTitle'),
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
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${formatQty(stin.quantityAdded)} ${i18n.unitLabel(stin.unit.code)} @ ${formatETB(stin.unitPurchaseCost)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: stin.isReversed
                                        ? ErpColors.textMuted
                                        : ErpColors.statusSuccess,
                                  ),
                                ),
                                Text(
                                  '${i18n.t('lblCost')}: ${formatETB(stin.previousUnitCost)} → ${formatETB(stin.newUnitCost)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: ErpColors.textSecondary,
                                  ),
                                ),
                                if (stin.supplierNote.isNotEmpty)
                                  Text(
                                    stin.supplierNote,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: ErpColors.textMuted,
                                    ),
                                  ),
                                if (stin.isReversed) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${i18n.t('reversedByLabel')}: ${stin.reversedBy ?? 'admin'} • ${stin.reversalReason ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ErpColors.statusDanger,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                // 3. Stock Audits Tab
                filteredAudits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: ErpEmptyState(
                            icon: Icons.fact_check_outlined,
                            title: i18n.t('tabAudits'),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredAudits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final aud = filteredAudits[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: aud.isReversed
                                  ? ErpColors.surfaceElevated
                                  : ErpColors.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: aud.isReversed
                                    ? ErpColors.statusDanger
                                        .withValues(alpha: 0.35)
                                    : ErpColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              aud.id.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                decoration: aud.isReversed
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (aud.isReversed) ...[
                                            const SizedBox(width: 6),
                                            ErpStatusLabel(
                                              text: i18n.t('badgeReversed'),
                                              textColor: ErpColors.statusDanger,
                                              backgroundColor:
                                                  ErpColors.statusDangerBg,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!aud.isReversed)
                                      ErpButton(
                                        label: i18n.t('btnReverse'),
                                        icon: Icons.undo_rounded,
                                        variant: ErpButtonVariant.danger,
                                        isCompact: true,
                                        onPressed: () async {
                                          final res =
                                              await ConfirmActionDialog.show(
                                            context,
                                            title:
                                                i18n.t('confirmReverseTitle'),
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
                                      fontWeight: FontWeight.w600,
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            adj.materialName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: ErpColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${formatQty(adj.expectedStock)} → ${formatQty(adj.physicalCount)} (${adj.variance >= 0 ? '+' : ''}${formatQty(adj.variance)})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ErpColors.textPrimary,
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
