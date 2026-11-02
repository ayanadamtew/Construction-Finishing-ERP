import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/erp_constants.dart';
import 'core/theme/erp_theme.dart';
import 'presentation/providers/erp_providers.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/inventory_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/materials_screen.dart';
import 'presentation/screens/more_screen.dart';
import 'presentation/screens/sales_pos_screen.dart';

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

    // 5-Tab Simplified Mobile Navigation Architecture:
    // 0: Dashboard
    // 1: Materials
    // 2: Sales
    // 3: Inventory (Stock-In & Stock Audit)
    // 4: More (Transaction History, Reports, Settings, User Management)
    const screens = [
      DashboardScreen(),
      MaterialsScreen(),
      SalesPosScreen(),
      InventoryScreen(),
      MoreScreen(),
    ];

    final safeTabIndex = viewState.activeTabIndex.clamp(0, screens.length - 1);

    return MaterialApp(
      title: i18n.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: ErpTheme.lightTheme,
      home: currentUser == null
          ? const LoginScreen()
          : Scaffold(
              appBar: AppBar(
                titleSpacing: 16,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ErpColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.architecture_rounded,
                        size: 18,
                        color: ErpColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        i18n.t('appTitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Compact Profile / Account Menu Trigger (replaces crowded header buttons)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => controller.openMoreSubTab(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ErpColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: ErpColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: ErpColors.primary,
                              child: Text(
                                currentUser.fullName.isNotEmpty
                                    ? currentUser.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 92),
                              child: Text(
                                currentUser.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ErpColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: ErpColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: ErpColors.borderSubtle),
                ),
              ),
              body: Column(
                children: [
                  if (viewState.bannerMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      color: viewState.isBannerError
                          ? ErpColors.statusDangerBg
                          : ErpColors.statusSuccessBg,
                      child: Row(
                        children: [
                          Icon(
                            viewState.isBannerError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: viewState.isBannerError
                                ? ErpColors.statusDanger
                                : ErpColors.statusSuccess,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewState.bannerMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: viewState.isBannerError
                                    ? ErpColors.statusDanger
                                    : ErpColors.statusSuccess,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: controller.clearBanner,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: safeTabIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: ErpColors.borderSubtle),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: safeTabIndex,
                  onDestinationSelected: controller.setActiveTab,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: i18n.t('navDashboard'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2_rounded),
                      label: i18n.t('navMaterials'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.point_of_sale_outlined),
                      selectedIcon: const Icon(Icons.point_of_sale_rounded),
                      label: i18n.t('navSales'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.warehouse_outlined),
                      selectedIcon: const Icon(Icons.warehouse_rounded),
                      label: i18n.t('navInventory'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.more_horiz_rounded),
                      selectedIcon: const Icon(Icons.more_horiz_rounded),
                      label: i18n.t('navMore'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
