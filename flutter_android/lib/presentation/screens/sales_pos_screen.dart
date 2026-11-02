import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-04` — Redesigned Multi-Item Sales Point-of-Sale
/// Fast, one-handed workflow:
/// - Search and select material
/// - Enter quantity & unit selling price
/// - See calculated line total and cart receipt total clearly
/// - Confirm sale with a single tap
class SalesPosScreen extends ConsumerStatefulWidget {
  const SalesPosScreen({super.key});

  @override
  ConsumerState<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends ConsumerState<SalesPosScreen> {
  String? _selectedMaterialId;
  String _searchFilter = '';
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final allMaterials = viewState.erpState.materials
        .where((m) => !m.isArchived)
        .toList();

    final filteredMaterials = allMaterials.where((m) {
      final q = _searchFilter.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.specs.toLowerCase().contains(q);
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
    final previewLineTotal =
        enteredQty > 0 && enteredPrice >= 0 ? round2(enteredQty * enteredPrice) : 0.0;

    final materialMap = {for (final m in allMaterials) m.id: m};
    double cartTotal = 0;
    double cartEstimatedProfit = 0;

    for (final line in viewState.draftCart) {
      final mat = materialMap[line.materialId];
      final lineTotal = round2(line.quantity * line.unitSellingPrice);
      final lineProfit = mat != null
          ? round2(line.quantity * (line.unitSellingPrice - mat.unitCost))
          : 0.0;
      cartTotal = round2(cartTotal + lineTotal);
      cartEstimatedProfit = round2(cartEstimatedProfit + lineProfit);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
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
                    child: Row(
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
                                '${formatQty(line.quantity)} ${mat != null ? i18n.unitLabel(mat.unit.code) : ''} × ${formatETB(line.unitSellingPrice)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ErpColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  );
                }),
              const Divider(height: 20, color: ErpColors.borderSubtle),
              ErpInputField(
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
                onPressed: viewState.draftCart.isEmpty
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
