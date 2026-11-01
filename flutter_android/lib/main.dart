import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/erp_constants.dart';
import 'l10n/erp_localizations.dart';
import 'presentation/providers/erp_providers.dart';
import 'presentation/screens/admin_management_sheet.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/materials_screen.dart';
import 'presentation/screens/sales_pos_screen.dart';
import 'presentation/screens/stock_audit_screen.dart';
import 'presentation/screens/stock_in_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SenayConstructionErpApp(),
    ),
  );
}

class SenayConstructionErpApp extends ConsumerWidget {
  const SenayConstructionErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final currentUser = viewState.currentUser;

    final screens = const [
      DashboardScreen(),
      MaterialsScreen(),
      SalesPosScreen(),
      StockInScreen(),
      StockAuditScreen(),
      HistoryScreen(),
    ];

    return MaterialApp(
      title: i18n.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: ErpColors.bgPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ErpColors.accentTerracotta,
          surface: ErpColors.surfaceCard,
        ),
      ),
      home: currentUser == null
          ? const LoginScreen()
          : Builder(
              builder: (scaffoldContext) => Scaffold(
                appBar: AppBar(
                  backgroundColor: ErpColors.textPrimary,
                  foregroundColor: Colors.white,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('appTitle'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${currentUser.fullName} (${currentUser.role.code.toUpperCase()})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD6D3CD),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (currentUser.role == UserRole.admin)
                      IconButton(
                        tooltip: i18n.t('btnAdminPanel'),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            AdminManagementSheet.show(scaffoldContext),
                      ),
                    // Persistent Trilingual Switcher (EN | አማ | OM)
                    Row(
                      children: AppLanguage.values.map((lang) {
                        final active = viewState.language == lang;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => controller.setLanguage(lang),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? ErpColors.accentTerracotta
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: active
                                      ? ErpColors.accentTerracotta
                                      : const Color(0xFF57534E),
                                ),
                              ),
                              child: Text(
                                lang.shortBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    IconButton(
                      tooltip: i18n.t('btnSignOut'),
                      icon: const Icon(Icons.logout, size: 19),
                      onPressed: () => controller.logout(),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    if (viewState.bannerMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        color: viewState.isBannerError
                            ? ErpColors.statusDangerBg
                            : ErpColors.statusSuccessBg,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                viewState.bannerMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: viewState.isBannerError
                                      ? ErpColors.statusDanger
                                      : ErpColors.statusSuccess,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: controller.clearBanner,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: viewState.activeTabIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: viewState.activeTabIndex,
                  onDestinationSelected: controller.setActiveTab,
                  backgroundColor: ErpColors.surfaceCard,
                  indicatorColor: const Color(0xFFFDE68A),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      label: i18n.t('navDashboard'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.category_outlined),
                      label: i18n.t('navMaterials'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.point_of_sale_outlined),
                      label: i18n.t('navSalesPos'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: i18n.t('navStockIn'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.fact_check_outlined),
                      label: i18n.t('navAudit'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.history_outlined),
                      label: i18n.t('navHistory'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
