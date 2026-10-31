import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';

/// `SCR-04` — Multi-Item Sales Point-of-Sale (`docs/UI_UX_SPEC.md` Section 5.4)
class SalesPosScreen extends ConsumerStatefulWidget {
  const SalesPosScreen({super.key});

  @override
  ConsumerState<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends ConsumerState<SalesPosScreen> {
  String? _selectedMaterialId;
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
    final materials = viewState.erpState.materials;

    final selectedMat = materials
        .where((m) => m.id == (_selectedMaterialId ?? materials.firstOrNull?.id))
        .firstOrNull;

    if (_selectedMaterialId == null && selectedMat != null) {
      _selectedMaterialId = selectedMat.id;
      _priceCtrl.text = selectedMat.defaultSellingPrice.toStringAsFixed(2);
    }

    final materialMap = {for (final m in materials) m.id: m};
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          i18n.t('posTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ErpColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Add Item Builder Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMat?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: i18n.t('posSelectMaterial'),
                  border: const OutlineInputBorder(),
                ),
                items: materials
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (${i18n.t('posAvailable')}: ${formatQty(m.currentStock)} ${i18n.unitLabel(m.unit.code)})',
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
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: i18n.t('posQuantity'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: i18n.t('posUnitPrice'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
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
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(i18n.t('btnAddCartLine')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Sale Cart
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ErpColors.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ErpColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewState.draftCart.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    i18n.t('posCartEmpty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ErpColors.textSecondary),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverStock
                          ? ErpColors.statusDangerBg
                          : ErpColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mat?.name ?? line.materialId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                        Text(
                          formatETB(lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () =>
                              controller.removeCartItem(line.materialId),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: ErpColors.statusDanger,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 24, color: ErpColors.borderSubtle),
              TextField(
                onChanged: controller.updateDraftCustomerNote,
                decoration: InputDecoration(
                  labelText: i18n.t('posCustomerNote'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.t('posTotalAmount'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatETB(cartTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ErpColors.accentTerracotta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.t('posEstimatedProfit'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: ErpColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatETB(cartEstimatedProfit),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.statusSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.accentTerracotta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: viewState.draftCart.isEmpty
                    ? null
                    : () => controller.completeDraftSale(),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  i18n.t('btnCompleteSale'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
