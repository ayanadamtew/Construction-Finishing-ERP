import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/services/inventory_engine.dart';
import '../../l10n/erp_localizations.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'admin_management_sheet.dart';
import 'history_screen.dart';

/// Unified More Screen (Tab 5) providing clean access to:
/// 0: Transaction History (Sales, Stock-In, Audits + Reversals)
/// 1: Reports (Valuation & Profit Breakdown by Category)
/// 2: Settings (Language Selection, Companion Sync, Account & Logout, Users & Categories)
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final subTab = viewState.moreSubTab.clamp(0, 2);

    return Column(
      children: [
        Container(
          color: ErpColors.surfaceCard,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ErpSegmentedControl(
            selectedIndex: subTab,
            onChanged: controller.openMoreSubTab,
            segments: [
              (
                label: i18n.t('navHistory'),
                icon: Icons.receipt_long_outlined,
              ),
              (
                label: i18n.t('navReports'),
                icon: Icons.bar_chart_rounded,
              ),
              (
                label: i18n.t('navSettings'),
                icon: Icons.tune_rounded,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ErpColors.borderSubtle),
        Expanded(
          child: IndexedStack(
            index: subTab,
            children: const [
              HistoryScreen(),
              _ReportsSubView(),
              _SettingsSubView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsSubView extends ConsumerWidget {
  const _ReportsSubView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final i18n = viewState.i18n;
    final erp = viewState.erpState;
    final summary = erp.summary;
    final activeMaterials =
        erp.materials.where((m) => !m.isArchived).toList();
    final categories = erp.categories.isNotEmpty
        ? erp.categories
        : InventoryEngine.createDefaultCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ErpSectionHeader(title: i18n.t('reportsSectionTitle')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiTotalRevenue'),
                value: formatETB(summary.cumulativeSalesRevenue),
                subtitle:
                    '${i18n.t('kpiTodayRevenue')}: ${formatETB(summary.todaySalesRevenue)}',
                icon: Icons.payments_outlined,
                accentColor: ErpColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('kpiTotalProfit'),
                value: formatETB(summary.cumulativeSalesProfit),
                subtitle:
                    '${i18n.t('kpiTodayProfit')}: ${formatETB(summary.todaySalesProfit)}',
                icon: Icons.trending_up_rounded,
                accentColor: ErpColors.statusSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('costValuationLabel'),
                value: formatETB(summary.totalStockValuationCost),
                subtitle:
                    '${activeMaterials.length} ${i18n.t('kpiMaterialsCount')}',
                icon: Icons.inventory_2_outlined,
                accentColor: ErpColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErpSummaryCard(
                label: i18n.t('retailValuationLabel'),
                value: formatETB(summary.totalStockValuationRetail),
                subtitle: '${erp.sales.length} ${i18n.t('tabSales')}',
                icon: Icons.storefront_outlined,
                accentColor: ErpColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ErpSectionHeader(
          title: i18n.t('tabCategories'),
          count: categories.length,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            children: categories.map((cat) {
              final items = activeMaterials
                  .where((m) => m.effectiveCategoryCode == cat.code)
                  .toList();
              final costVal = items.fold<double>(
                0,
                (sum, m) => round2(sum + (m.currentStock * m.unitCost)),
              );
              final retailVal = items.fold<double>(
                0,
                (sum, m) =>
                    round2(sum + (m.currentStock * m.defaultSellingPrice)),
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: ErpColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i18n.categoryLabel(cat.code, customName: cat.name),
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
                            '${items.length} ${i18n.t('itemsCount')}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ErpColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatETB(costVal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${i18n.t('lblPrice')}: ${formatETB(retailVal)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsSubView extends ConsumerWidget {
  const _SettingsSubView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final currentUser = viewState.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Language Switcher Card (Moved out of crowded header!)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: ErpColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i18n.t('languageSettingTitle'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                i18n.t('languageSettingSubtitle'),
                style: const TextStyle(
                  fontSize: 12,
                  color: ErpColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: AppLanguage.values.map((lang) {
                  final active = viewState.language == lang;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => controller.setLanguage(lang),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? ErpColors.primaryLight
                                : ErpColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? ErpColors.primary
                                  : ErpColors.borderSubtle,
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                lang.shortBadge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? ErpColors.primaryDark
                                      : ErpColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang.nativeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: active
                                      ? ErpColors.primaryDark
                                      : ErpColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Administration & Categories Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 19,
                    color: ErpColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i18n.t('adminPanelTitle'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ErpColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${viewState.publicUsers.length} ${i18n.t('tabUsers')} • ${viewState.erpState.categories.length} ${i18n.t('tabCategories')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ErpColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ErpButton(
                label: i18n.t('navUsers'),
                icon: Icons.manage_accounts_outlined,
                variant: ErpButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => AdminManagementSheet.show(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Companion Server Sync Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i18n.t('companionSyncToggle'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          i18n.t('appSubtitle'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: viewState.companionSyncEnabled,
                    activeTrackColor: ErpColors.primaryLight,
                    activeThumbColor: ErpColors.primary,
                    onChanged: controller.toggleCompanionSync,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ErpButton(
                label: i18n.t('btnSyncServer'),
                icon: Icons.sync_rounded,
                variant: ErpButtonVariant.secondary,
                isFullWidth: true,
                onPressed: viewState.isLoading
                    ? null
                    : () => controller.syncWithCompanionServer(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Signed-In Account & Logout Card
        if (currentUser != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ErpColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ErpColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: ErpColors.primaryLight,
                      child: Text(
                        currentUser.fullName.isNotEmpty
                            ? currentUser.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ErpColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                          Text(
                            '@${currentUser.username} • ${currentUser.role.code.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ErpButton(
                  label: i18n.t('btnSignOut'),
                  icon: Icons.logout_rounded,
                  variant: ErpButtonVariant.danger,
                  isFullWidth: true,
                  onPressed: () => controller.logout(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 5. About EFA Card (Developer Information & Project Metadata)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: ErpColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: ErpColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i18n.t('aboutEfaTitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${ErpAppInfo.appName} v${ErpAppInfo.appVersion} (${i18n.t('buildNumberLabel')} ${ErpAppInfo.buildNumber})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ErpColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: ErpColors.borderSubtle),
              _AboutInfoRow(
                label: i18n.t('developerNameLabel'),
                value: ErpAppInfo.developerName,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 8),
              _AboutInfoRow(
                label: i18n.t('developerPhoneLabel'),
                value: ErpAppInfo.developerPhone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 8),
              _AboutInfoRow(
                label: i18n.t('appVersionLabel'),
                value: ErpAppInfo.appVersion,
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 8),
              _AboutInfoRow(
                label: i18n.t('buildNumberLabel'),
                value: ErpAppInfo.buildNumber,
                icon: Icons.tag_rounded,
              ),
              const SizedBox(height: 10),
              Text(
                i18n.t('appDescriptionLabel'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: ErpColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ErpAppInfo.appDescription,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: ErpColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AboutInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ErpColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ErpColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ErpColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
