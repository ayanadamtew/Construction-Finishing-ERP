import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/services/inventory_engine.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-01` — Redesigned Minimal Operational Dashboard
/// - Compact, overflow-safe 2x2 summary grid (Today's sales, Today's revenue, Total materials, Need restock)
/// - Quick 1-hand operational actions (New Sale, Stock-In)
/// - Limited Low-Stock Materials list (max 4 items) with "View All" action
/// - Clean Recent Sales list (max 4 items) with "View All" action
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final erp = viewState.erpState;
    final summary = erp.summary;
    final categories = erp.categories.isNotEmpty
        ? erp.categories
        : InventoryEngine.createDefaultCategories();

    final lowStockMaterials = erp.materials
        .where((m) => !m.isArchived && m.currentStock <= m.minStockLevel)
        .toList();

    final activeSales =
        erp.sales.where((s) => !s.isReversed).toList();
    final recentSales = activeSales.take(4).toList();
    final displayedLowStock = lowStockMaterials.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // 1. Compact 2x2 Summary Section (Overflow-Safe Rows instead of fixed-aspect GridView)
        Row(
          children: [
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiTodaySales'),
                value: '${activeSales.length}',
                subtitle: '${erp.sales.length} ${i18n.t('kpiTransactionsCount')}',
                icon: Icons.receipt_long_outlined,
                accentColor: ErpColors.primary,
                onTap: () => controller.openMoreSubTab(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiTodayRevenue'),
                value: formatETB(summary.todaySalesRevenue),
                subtitle:
                    '${i18n.t('profitLabel')}: ${formatETB(summary.todaySalesProfit)}',
                icon: Icons.payments_outlined,
                accentColor: ErpColors.statusSuccess,
                onTap: () => controller.openMoreSubTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiMaterialsCount'),
                value: '${summary.totalMaterials}',
                subtitle: formatETB(summary.totalStockValuationCost),
                icon: Icons.inventory_2_outlined,
                accentColor: ErpColors.textPrimary,
                onTap: () => controller.setActiveTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiRestockRequired'),
                value: '${summary.lowStockCount}',
                subtitle: summary.lowStockCount > 0
                    ? i18n.t('statusLowStock')
                    : i18n.t('statusInStock'),
                icon: summary.lowStockCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                accentColor: summary.lowStockCount > 0
                    ? ErpColors.statusWarning
                    : ErpColors.statusSuccess,
                onTap: () => controller.setActiveTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Streamlined Quick Actions Bar
        Row(
          children: [
            Expanded(
              child: ErpButton(
                label: i18n.t('navSales'),
                icon: Icons.point_of_sale_rounded,
                variant: ErpButtonVariant.primary,
                isFullWidth: true,
                onPressed: () => controller.setActiveTab(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErpButton(
                label: i18n.t('navStockIn'),
                icon: Icons.south_west_rounded,
                variant: ErpButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => controller.openInventorySubTab(0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 3. Low-Stock Materials Section (Limited to 4 items + View All)
        ErpSectionHeader(
          title: i18n.t('lowStockSection'),
          count: lowStockMaterials.length,
          badgeColor: lowStockMaterials.isEmpty
              ? ErpColors.statusSuccess
              : ErpColors.statusWarning,
          actionLabel: i18n.t('viewAll'),
          onAction: () => controller.setActiveTab(1),
        ),
        const SizedBox(height: 8),
        if (lowStockMaterials.isEmpty)
          ErpEmptyState(
            icon: Icons.verified_outlined,
            title: i18n.t('allStockHealthy'),
          )
        else
          ...displayedLowStock.map((m) {
            final catObj = categories
                .where((c) => c.code == m.effectiveCategoryCode)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErpMaterialListItem(
                material: m,
                categoryLabel: i18n.categoryLabel(
                  m.effectiveCategoryCode,
                  customName: catObj?.name,
                ),
                i18n: i18n,
                compact: true,
                onTap: () => controller.openInventorySubTab(0),
                onQuickAction: () => controller.openInventorySubTab(0),
                quickActionIcon: Icons.add_circle_outline_rounded,
                quickActionTooltip: i18n.t('navStockIn'),
              ),
            );
          }),

        const SizedBox(height: 18),

        // 4. Recent Sales Section (Clean list + View All)
        ErpSectionHeader(
          title: i18n.t('recentSalesSection'),
          count: activeSales.length,
          actionLabel: i18n.t('viewAll'),
          onAction: () => controller.openMoreSubTab(0),
        ),
        const SizedBox(height: 8),
        if (recentSales.isEmpty)
          ErpEmptyState(
            icon: Icons.receipt_long_outlined,
            title: i18n.t('noRecentSales'),
            actionLabel: i18n.t('navSales'),
            onAction: () => controller.setActiveTab(2),
          )
        else
          ...recentSales.map((sale) {
            final datePart = sale.createdAt.split('T').first;
            final refTitle = sale.customerNote.trim().isNotEmpty
                ? sale.customerNote
                : sale.id.toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErpTransactionListItem(
                title: refTitle,
                subtitle:
                    '${sale.id.toUpperCase()} • $datePart • ${sale.items.length} ${i18n.t('itemsCount')}',
                amountText: formatETB(sale.totalAmount),
                secondaryAmountText:
                    '+${formatETB(sale.totalProfit)} ${i18n.t('profitLabel')}',
                onTap: () => controller.openMoreSubTab(0),
              ),
            );
          }),
      ],
    );
  }
}
