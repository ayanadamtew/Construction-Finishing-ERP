import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../providers/erp_providers.dart';
import '../widgets/erp_components.dart';
import 'confirm_action_dialog.dart';

/// `SCR-05` — Redesigned Supplier Stock-In & Weighted-Average Cost Calculator (`BR-006`)
class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  String? _selectedMaterialId;
  String? _lastSyncedDeepLinkMaterialId;
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

    // Sync deep-linked material from Dashboard or Materials Detail Sheet
    final deepLinkedId = viewState.selectedStockInMaterialId;
    if (deepLinkedId != null &&
        deepLinkedId != _lastSyncedDeepLinkMaterialId &&
        materials.any((m) => m.id == deepLinkedId)) {
      _lastSyncedDeepLinkMaterialId = deepLinkedId;
      _selectedMaterialId = deepLinkedId;
      final m = materials.firstWhere((x) => x.id == deepLinkedId);
      _costCtrl.text = m.unitCost.toStringAsFixed(2);
    }

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
    final totalRestockCost = round2(
      (qtyAdded > 0 ? qtyAdded : 0) * (purchaseCost >= 0 ? purchaseCost : 0),
    );
    final prevStock = selectedMat?.currentStock ?? 0;
    final prevCost = selectedMat?.unitCost ?? 0;
    final newStock = round2(prevStock + (qtyAdded > 0 ? qtyAdded : 0));
    final previewNewUnitCost = newStock > 0 && qtyAdded > 0
        ? round2(
            ((prevStock * prevCost) + (qtyAdded * purchaseCost)) / newStock,
          )
        : prevCost;
    final unitStr =
        selectedMat != null ? i18n.unitLabel(selectedMat.unit.code) : '';

    final recentStockIns = viewState.erpState.stockIns.take(8).toList();

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
                  controller.selectStockInMaterial(val);
                  setState(() {
                    _selectedMaterialId = val;
                    _lastSyncedDeepLinkMaterialId = val;
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
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          i18n.t('stockInTotalRestockCost'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                        Text(
                          formatETB(totalRestockCost),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ErpColors.textPrimary,
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
        if (recentStockIns.isNotEmpty) ...[
          const SizedBox(height: 20),
          ErpSectionHeader(
            title: i18n.t('stockInRecentDeliveries'),
            count: viewState.erpState.stockIns.length,
          ),
          const SizedBox(height: 8),
          ...recentStockIns.map((stin) {
            final datePart = stin.createdAt.split('T').first;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stin.isReversed
                    ? ErpColors.surfaceElevated
                    : ErpColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stin.isReversed
                      ? ErpColors.statusDanger.withValues(alpha: 0.35)
                      : ErpColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                stin.materialName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: stin.isReversed
                                      ? ErpColors.textMuted
                                      : ErpColors.textPrimary,
                                  decoration: stin.isReversed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (stin.isReversed) ...[
                              const SizedBox(width: 6),
                              ErpStatusLabel(
                                text: i18n.t('badgeReversed'),
                                textColor: ErpColors.statusDanger,
                                backgroundColor: ErpColors.statusDangerBg,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+${formatQty(stin.quantityAdded)} ${i18n.unitLabel(stin.unit.code)} @ ${formatETB(stin.unitPurchaseCost)} • $datePart',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!stin.isReversed)
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
                              '${stin.id.toUpperCase()} — ${stin.materialName} (+${formatQty(stin.quantityAdded)})',
                          description:
                              'Reversing this Stock-In deducts the added quantity and restores the previous weighted-average unit cost.',
                          confirmLabel: i18n.t('btnReverse'),
                          requireReason: true,
                          i18n: i18n,
                        );
                        if (res != null && res.confirmed) {
                          await controller.reverseStockIn(stin.id, res.reason);
                        }
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
