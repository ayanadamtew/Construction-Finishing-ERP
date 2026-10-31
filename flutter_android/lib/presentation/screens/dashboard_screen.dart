import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';

/// `SCR-01` — Operational Dashboard & Profit Summary (`docs/UI_UX_SPEC.md` Section 5.1)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final summary = viewState.erpState.summary;
    final lowStockMaterials = viewState.erpState.materials
        .where((m) => m.currentStock <= m.minStockLevel)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 2x2 Primary KPI Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            _KpiCard(
              label: i18n.t('kpiStockValuation'),
              value: formatETB(summary.totalStockValuationCost),
              subValue: '${summary.totalMaterials} ${i18n.t('kpiMaterialsCount')}',
              accentColor: ErpColors.textPrimary,
            ),
            _KpiCard(
              label: i18n.t('kpiTodayRevenue'),
              value: formatETB(summary.todaySalesRevenue),
              subValue: '${i18n.t('kpiTotalRevenue')}: ${formatETB(summary.cumulativeSalesRevenue)}',
              accentColor: ErpColors.accentTerracotta,
            ),
            _KpiCard(
              label: i18n.t('kpiTodayProfit'),
              value: formatETB(summary.todaySalesProfit),
              subValue: '${i18n.t('kpiTotalProfit')}: ${formatETB(summary.cumulativeSalesProfit)}',
              accentColor: ErpColors.statusSuccess,
            ),
            _KpiCard(
              label: i18n.t('kpiLowStock'),
              value: '${summary.lowStockCount}',
              subValue: i18n.t('lowStockSection'),
              accentColor: summary.lowStockCount > 0
                  ? ErpColors.statusDanger
                  : ErpColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Operational Actions
        Text(
          i18n.t('quickActions').toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: ErpColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ErpColors.accentTerracotta,
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 48),
              ),
              onPressed: () => controller.setActiveTab(2),
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: Text(i18n.t('navSalesPos')),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ErpColors.textPrimary,
                side: const BorderSide(color: ErpColors.borderStrong),
                minimumSize: const Size(140, 48),
              ),
              onPressed: () => controller.setActiveTab(3),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: Text(i18n.t('navStockIn')),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ErpColors.textPrimary,
                side: const BorderSide(color: ErpColors.borderStrong),
                minimumSize: const Size(140, 48),
              ),
              onPressed: () => controller.setActiveTab(4),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: Text(i18n.t('navAudit')),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Low-Stock Watchlist Panel
        Container(
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.t('lowStockSection'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: lowStockMaterials.isEmpty
                          ? ErpColors.statusSuccessBg
                          : ErpColors.statusWarningBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${lowStockMaterials.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: lowStockMaterials.isEmpty
                            ? ErpColors.statusSuccess
                            : ErpColors.statusWarning,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: ErpColors.borderSubtle),
              if (lowStockMaterials.isEmpty)
                Text(
                  i18n.t('allStockHealthy'),
                  style: const TextStyle(color: ErpColors.textSecondary),
                )
              else
                ...lowStockMaterials.map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ErpColors.textPrimary,
                                ),
                              ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatQty(m.currentStock)} / ${formatQty(m.minStockLevel)} ${i18n.unitLabel(m.unit.code)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: m.isOutOfStock
                                    ? ErpColors.statusDanger
                                    : ErpColors.statusWarning,
                              ),
                            ),
                            Text(
                              m.isOutOfStock
                                  ? i18n.t('statusOutStock')
                                  : i18n.t('statusLowStock'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: m.isOutOfStock
                                    ? ErpColors.statusDanger
                                    : ErpColors.statusWarning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color accentColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ErpColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ErpColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: ErpColors.textSecondary,
            ),
          ),
           FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: ErpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
