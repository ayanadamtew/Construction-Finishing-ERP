import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'stock_audit_screen.dart';
import 'stock_in_screen.dart';

/// Unified Inventory Screen (Tab 4) providing clean, one-handed access to:
/// - Supplier Stock-In & Weighted-Average Cost Calculator (`SCR-05`)
/// - Physical Ground-Stock Audit & Variance Reconciliation (`SCR-06`)
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final subTab = viewState.inventorySubTab.clamp(0, 1);

    return Column(
      children: [
        Container(
          color: ErpColors.surfaceCard,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ErpSegmentedControl(
            selectedIndex: subTab,
            onChanged: controller.openInventorySubTab,
            segments: [
              (
                label: i18n.t('navStockIn'),
                icon: Icons.south_west_rounded,
              ),
              (
                label: i18n.t('navAudit'),
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ErpColors.borderSubtle),
        Expanded(
          child: IndexedStack(
            index: subTab,
            children: const [
              StockInScreen(),
              StockAuditScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
