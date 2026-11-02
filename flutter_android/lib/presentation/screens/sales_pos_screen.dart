import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/inventory_engine.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'confirm_action_dialog.dart';

/// `SCR-04` — Redesigned Multi-Item Sales Point-of-Sale
/// Fast, one-handed workflow with full Web parity:
/// - Search and filter materials by category
/// - Enter quantity & unit selling price
/// - Inline cart quantity steppers (- / +), remaining stock after sale, Clear Cart
/// - Last Completed Sale Receipt banner with instant Reverse option
class SalesPosScreen extends ConsumerStatefulWidget {
  const SalesPosScreen({super.key});

  @override
  ConsumerState<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends ConsumerState<SalesPosScreen> {
  String? _selectedMaterialId;
  String _searchFilter = '';
  String _selectedCategory = 'all';
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _customerNoteCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _customerNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final categories = viewState.erpState.categories.isNotEmpty
        ? viewState.erpState.categories
        : InventoryEngine.createDefaultCategories();
    final allMaterials = viewState.erpState.materials
        .where((m) => !m.isArchived)
        .toList();

    if (_customerNoteCtrl.text != viewState.draftCustomerNote) {
      _customerNoteCtrl.value = TextEditingValue(
        text: viewState.draftCustomerNote,
        selection: TextSelection.collapsed(
          offset: viewState.draftCustomerNote.length,
        ),
      );
    }

    final filteredMaterials = allMaterials.where((m) {
      final matchesCategory = _selectedCategory == 'all' ||
          m.effectiveCategoryCode == _selectedCategory;
      final q = _searchFilter.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.specs.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    final selectedMat = filteredMaterials
            .where((m) => m.id == _selectedMaterialId)
            .firstOrNull ??
        filteredMaterials.firstOrNull ??
        allMaterials.firstOrNull;

    if (_selectedMaterialId != selectedMat?.id && selectedMat != null) {
      _selectedMaterialId = selectedMat.id;
      _priceCtrl.text = selectedMat.defaultSellingPrice.toStringAsFixed(2);
    }

    final enteredQty = double.tryParse(_qtyCtrl.text) ?? 0;
    final enteredPrice = double.tryParse(_priceCtrl.text) ?? 0;
    final previewLineTotal = enteredQty > 0 && enteredPrice >= 0
        ? round2(enteredQty * enteredPrice)
        : 0.0;

    final materialMap = {for (final m in allMaterials) m.id: m};
    double cartTotal = 0;
    double cartEstimatedProfit = 0;
    bool hasOverStockLine = false;

    for (final line in viewState.draftCart) {
      final mat = materialMap[line.materialId];
      if (mat != null && line.quantity > mat.currentStock) {
        hasOverStockLine = true;
      }
      final lineTotal = round2(line.quantity * line.unitSellingPrice);
      final lineProfit = mat != null
          ? round2(line.quantity * (line.unitSellingPrice - mat.unitCost))
          : 0.0;
      cartTotal = round2(cartTotal + lineTotal);
      cartEstimatedProfit = round2(cartEstimatedProfit + lineProfit);
    }

    final lastSale = viewState.lastCompletedSale;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // 0. Last Completed Sale Receipt Banner (Parity with Web SalesView.tsx)
        if (lastSale != null && !lastSale.isReversed) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ErpColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ErpColors.statusSuccess.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: ErpColors.statusSuccess,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${i18n.t('posReceiptBannerTitle')} • ${lastSale.id.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ErpColors.statusSuccess,
                        ),
                      ),
                    ),
                    Text(
                      formatETB(lastSale.totalAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ErpColors.statusSuccess,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...lastSale.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.materialName} (${formatQty(item.quantity)} ${i18n.unitLabel(item.unit.code)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatETB(item.lineTotal),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: controller.dismissLastCompletedSale,
                      child: Text(
                        i18n.t('btnDismissReceipt'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ErpButton(
                      label: i18n.t('btnReverse'),
                      icon: Icons.undo_rounded,
                      variant: ErpButtonVariant.danger,
                      isCompact: true,
                      onPressed: () async {
                        final res = await ConfirmActionDialog.show(
                          context,
                          title: i18n.t('confirmReverseTitle'),
                          recordName:
                              '${lastSale.id.toUpperCase()} (${formatETB(lastSale.totalAmount)})',
                          description:
                              'Reversing this sale restores all sold material quantities to stock while preserving the original receipt in the audit trail.',
                          confirmLabel: i18n.t('btnReverse'),
                          requireReason: true,
                          i18n: i18n,
                        );
                        if (res != null && res.confirmed) {
                          await controller.reverseSale(lastSale.id, res.reason);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 1. Fast Item Entry Card
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
              ErpSearchBar(
                hintText: i18n.t('searchMaterialsHint'),
                value: _searchFilter,
                onChanged: (v) => setState(() => _searchFilter = v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PosCategoryChip(
                      label: i18n.t('filterAllCategories'),
                      isSelected: _selectedCategory == 'all',
                      onTap: () => setState(() => _selectedCategory = 'all'),
                    ),
                    ...categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _PosCategoryChip(
                          label: i18n.categoryLabel(c.code, customName: c.name),
                          isSelected: _selectedCategory == c.code,
                          onTap: () =>
                              setState(() => _selectedCategory = c.code),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedMat != null &&
                        filteredMaterials.any((m) => m.id == selectedMat.id)
                    ? selectedMat.id
                    : filteredMaterials.firstOrNull?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: i18n.t('posSelectMaterial'),
                ),
                items: filteredMaterials
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (${formatQty(m.currentStock)} ${i18n.unitLabel(m.unit.code)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  final m = materialMap[val];
                  setState(() {
                    _selectedMaterialId = val;
                    if (m != null) {
                      _priceCtrl.text =
                          m.defaultSellingPrice.toStringAsFixed(2);
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ErpInputField(
                      controller: _qtyCtrl,
                      label: i18n.t('posQuantity'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ErpInputField(
                      controller: _priceCtrl,
                      label: i18n.t('posUnitPrice'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Live Line Preview Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        selectedMat != null
                            ? '${i18n.t('posAvailable')}: ${formatQty(selectedMat.currentStock)} ${i18n.unitLabel(selectedMat.unit.code)}'
                            : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ErpColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      formatETB(previewLineTotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ErpColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ErpButton(
                label: i18n.t('btnAddCartLine'),
                icon: Icons.add_shopping_cart_rounded,
                variant: ErpButtonVariant.secondary,
                isFullWidth: true,
                onPressed: selectedMat == null
                    ? null
                    : () {
                        final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                        final price = double.tryParse(_priceCtrl.text) ?? 0;
                        if (qty <= 0) return;
                        controller.addOrUpdateCartItem(
                          SaleCartLineInput(
                            materialId: selectedMat.id,
                            quantity: qty,
                            unitSellingPrice: price,
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Active Sale Cart & Prominent Total Confirmation Card
        ErpSectionHeader(
          title: i18n.t('posTitle'),
          count: viewState.draftCart.length,
          actionLabel:
              viewState.draftCart.isNotEmpty ? i18n.t('btnClearCart') : null,
          onAction: viewState.draftCart.isNotEmpty
              ? controller.clearDraftCart
              : null,
        ),
        const SizedBox(height: 8),
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
              if (viewState.draftCart.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    i18n.t('posCartEmpty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ErpColors.textSecondary,
                    ),
                  ),
                )
              else
                ...viewState.draftCart.map((line) {
                  final mat = materialMap[line.materialId];
                  final lineTotal =
                      round2(line.quantity * line.unitSellingPrice);
                  final isOverStock =
                      mat != null && line.quantity > mat.currentStock;
                  final remainingAfterSale = mat != null
                      ? round2(mat.currentStock - line.quantity)
                      : 0.0;
                  final unitStr =
                      mat != null ? i18n.unitLabel(mat.unit.code) : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isOverStock
                          ? ErpColors.statusDangerBg
                          : ErpColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mat?.name ?? line.materialId,
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
                                    '${formatQty(line.quantity)} $unitStr × ${formatETB(line.unitSellingPrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ErpColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOverStock
                                        ? '${i18n.t('posStockExceededWarning')} (${formatQty(mat.currentStock)} $unitStr)'
                                        : '${i18n.t('posRemainingAfterSale')}: ${formatQty(remainingAfterSale)} $unitStr',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverStock
                                          ? ErpColors.statusDanger
                                          : ErpColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Inline - / + stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: '-1',
                                  onPressed: () =>
                                      controller.setCartItemQuantity(
                                    line.materialId,
                                    round2(line.quantity - 1),
                                  ),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                    color: ErpColors.textSecondary,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: '+1',
                                  onPressed: () =>
                                      controller.setCartItemQuantity(
                                    line.materialId,
                                    round2(line.quantity + 1),
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                    color: ErpColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatETB(lineTotal),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: ErpColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  controller.removeCartItem(line.materialId),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: ErpColors.statusDanger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 20, color: ErpColors.borderSubtle),
              ErpInputField(
                controller: _customerNoteCtrl,
                label: i18n.t('posCustomerNote'),
                prefixIcon: Icons.person_outline_rounded,
                onChanged: controller.updateDraftCustomerNote,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ErpColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ErpColors.primaryLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            i18n.t('posTotalAmount'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ErpColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          formatETB(cartTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ErpColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            i18n.t('posEstimatedProfit'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: ErpColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          formatETB(cartEstimatedProfit),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ErpButton(
                label: i18n.t('btnCompleteSale'),
                icon: Icons.check_circle_outline_rounded,
                variant: ErpButtonVariant.primary,
                isFullWidth: true,
                onPressed: viewState.draftCart.isEmpty || hasOverStockLine
                    ? null
                    : () => controller.completeDraftSale(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PosCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PosCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? ErpColors.primary : ErpColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? ErpColors.primary : ErpColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : ErpColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
