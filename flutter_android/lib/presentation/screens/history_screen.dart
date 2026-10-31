import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';

/// `SCR-07` — Immutable Transaction History Ledger (Sales, Stock-In, Audits)
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
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
                        color: ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sale.id.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                formatETB(sale.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ErpColors.accentTerracotta,
                                ),
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
                        color: ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stin.materialName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${formatQty(stin.quantityAdded)} ${i18n.unitLabel(stin.unit.code)} @ ${formatETB(stin.unitPurchaseCost)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ErpColors.statusSuccess,
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
                        color: ErpColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ErpColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aud.id.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (aud.auditNote.isNotEmpty)
                            Text(
                              aud.auditNote,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ErpColors.textSecondary,
                              ),
                            ),
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
