import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';

/// `SCR-05` — Redesigned Supplier Stock-In & Weighted-Average Cost Calculator (`BR-006`)
class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  String? _selectedMaterialId;
  final _qtyCtrl = TextEditingController(text: '50');
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(erpControllerProvider);
    final controller = ref.read(erpControllerProvider.notifier);
    final i18n = viewState.i18n;
    final materials = viewState.erpState.materials
        .where((m) => !m.isArchived)
        .toList();

    final selectedMat = materials
        .where(
          (m) => m.id == (_selectedMaterialId ?? materials.firstOrNull?.id),
        )
        .firstOrNull;

    if (_selectedMaterialId == null && selectedMat != null) {
      _selectedMaterialId = selectedMat.id;
      _costCtrl.text = selectedMat.unitCost.toStringAsFixed(2);
    }

    final qtyAdded = double.tryParse(_qtyCtrl.text) ?? 0;
    final purchaseCost = double.tryParse(_costCtrl.text) ?? 0;
    final prevStock = selectedMat?.currentStock ?? 0;
    final prevCost = selectedMat?.unitCost ?? 0;
    final newStock = round2(prevStock + (qtyAdded > 0 ? qtyAdded : 0));
    final previewNewUnitCost = newStock > 0 && qtyAdded > 0
        ? round2(((prevStock * prevCost) + (qtyAdded * purchaseCost)) / newStock)
        : prevCost;
    final unitStr =
        selectedMat != null ? i18n.unitLabel(selectedMat.unit.code) : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        ErpSectionHeader(title: i18n.t('stockInTitle')),
        const SizedBox(height: 10),
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
              DropdownButtonFormField<String>(
                value: selectedMat?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: i18n.t('stockInSelectMaterial'),
                ),
                items: materials
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
                  final m = materials.where((x) => x.id == val).firstOrNull;
                  setState(() {
                    _selectedMaterialId = val;
                    if (m != null) {
                      _costCtrl.text = m.unitCost.toStringAsFixed(2);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ErpInputField(
                      controller: _qtyCtrl,
                      label: i18n.t('stockInQuantityAdded'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ErpInputField(
                      controller: _costCtrl,
                      label: i18n.t('stockInUnitPurchaseCost'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ErpInputField(
                controller: _noteCtrl,
                label: i18n.t('stockInSupplierNote'),
                prefixIcon: Icons.local_shipping_outlined,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.t('stockInFormulaPreview'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ErpColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          i18n.t('lblStock'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${formatQty(prevStock)} → ${formatQty(newStock)} $unitStr',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          i18n.t('lblCost'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${formatETB(prevCost)} → ${formatETB(previewNewUnitCost)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ErpColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ErpButton(
                label: i18n.t('btnRecordStockIn'),
                icon: Icons.south_west_rounded,
                variant: ErpButtonVariant.primary,
                isFullWidth: true,
                onPressed: selectedMat == null
                    ? null
                    : () async {
                        final ok = await controller.recordStockIn(
                          RecordStockInInput(
                            materialId: selectedMat.id,
                            quantityAdded:
                                double.tryParse(_qtyCtrl.text) ?? 0,
                            unitPurchaseCost:
                                double.tryParse(_costCtrl.text) ?? 0,
                            supplierNote: _noteCtrl.text,
                          ),
                        );
                        if (ok) {
                          _noteCtrl.clear();
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
