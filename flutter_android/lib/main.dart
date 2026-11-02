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
      child: EfaErpApp(),
    ),
  );
}

typedef SenayConstructionErpApp = EfaErpApp;

class EfaErpApp extends ConsumerWidget {
  const EfaErpApp({super.key});

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
      title: ErpAppInfo.appName,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            i18n.t('appTitle'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                          Text(
                            i18n.t('appSubtitle'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: ErpColors.textSecondary,
                            ),
                          ),
                        ],
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
              bottomNavigationBar: _EfaBottomNavigationBar(
                selectedIndex: safeTabIndex,
                onDestinationSelected: controller.setActiveTab,
                items: [
                  _EfaNavItemData(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    label: i18n.t('navDashboard'),
                  ),
                  _EfaNavItemData(
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    label: i18n.t('navMaterials'),
                  ),
                  _EfaNavItemData(
                    icon: Icons.point_of_sale_outlined,
                    selectedIcon: Icons.point_of_sale_rounded,
                    label: i18n.t('navSales'),
                  ),
                  _EfaNavItemData(
                    icon: Icons.warehouse_outlined,
                    selectedIcon: Icons.warehouse_rounded,
                    label: i18n.t('navInventory'),
                  ),
                  _EfaNavItemData(
                    icon: Icons.more_horiz_rounded,
                    selectedIcon: Icons.more_horiz_rounded,
                    label: i18n.t('navMore'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EfaNavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _EfaNavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Custom 5-item bottom navigation bar engineered to guarantee zero horizontal
/// or vertical pixel overflow across compact screens (`320dp`, `360dp`, `390dp+`)
/// and long trilingual labels (`en`, `am`, `om`).
class _EfaBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_EfaNavItemData> items;

  const _EfaBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ErpColors.surfaceCard,
        border: Border(
          top: BorderSide(color: ErpColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  key: ValueKey('nav_tab_$index'),
                  onTap: () => onDestinationSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ErpColors.primaryLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 20,
                            color: isSelected
                                ? ErpColors.primaryDark
                                : ErpColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? ErpColors.textPrimary
                                    : ErpColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
