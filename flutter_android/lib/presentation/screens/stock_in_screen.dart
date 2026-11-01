import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';

/// `SCR-05` — Supplier Stock-In & Weighted-Average Cost Calculator (`BR-006`)
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
        .where((m) => m.id == (_selectedMaterialId ?? materials.firstOrNull?.id))
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          i18n.t('stockInTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ErpColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
                  labelText: i18n.t('stockInSelectMaterial'),
                  border: const OutlineInputBorder(),
                ),
                items: materials
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (${formatQty(m.currentStock)} ${i18n.unitLabel(m.unit.code)} @ ${formatETB(m.unitCost)})',
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
                    child: TextField(
                      controller: _qtyCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: i18n.t('stockInQuantityAdded'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _costCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: i18n.t('stockInUnitPurchaseCost'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: i18n.t('stockInSupplierNote'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ErpColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ErpColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.t('stockInFormulaPreview'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ErpColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatQty(prevStock)} → ${formatQty(newStock)} ${selectedMat != null ? i18n.unitLabel(selectedMat.unit.code) : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatETB(prevCost)} → ${formatETB(previewNewUnitCost)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ErpColors.accentTerracotta,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ErpColors.accentTerracotta,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
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
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  i18n.t('btnRecordStockIn'),
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
