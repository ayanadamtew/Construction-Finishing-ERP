import React, { useEffect, useMemo, useState } from 'react';
import {
  ArrowDownToLine,
  ArrowRight,
  PackagePlus,
  RotateCcw,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import {
  calculateWeightedAverageCost,
  round2,
} from '../domain/inventoryEngine';
import {
  formatETB,
  formatQuantity,
  getCategoryLabel,
} from '../i18n/translations';
import { StockInRecord } from '../types/erp';
import { ConfirmDialog } from './ConfirmDialog';

export const StockInView: React.FC = () => {
  const {
    state,
    t,
    selectedStockInMaterialId,
    setSelectedStockInMaterialId,
    submitStockIn,
    reverseStockIn,
  } = useErpStore();

  const { materials, stockIns, categories } = state;

  const activeMaterials = useMemo(
    () => materials.filter((m) => !m.isArchived),
    [materials]
  );

  const activeMaterial = useMemo(() => {
    if (activeMaterials.length === 0) return null;
    return (
      activeMaterials.find((m) => m.id === selectedStockInMaterialId) ||
      activeMaterials[0]
    );
  }, [activeMaterials, selectedStockInMaterialId]);

  const [quantityAddedInput, setQuantityAddedInput] = useState<string>('');
  const [unitPurchaseCostInput, setUnitPurchaseCostInput] =
    useState<string>('');
  const [supplierNote, setSupplierNote] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [showValidationErrors, setShowValidationErrors] =
    useState<boolean>(false);

  const [stockInToReverse, setStockInToReverse] =
    useState<StockInRecord | null>(null);

  // Sync default unit purchase cost when the selected material changes
  useEffect(() => {
    if (activeMaterial) {
      setUnitPurchaseCostInput(String(activeMaterial.unitCost));
      setShowValidationErrors(false);
    }
  }, [activeMaterial?.id]);

  const parsedQty = Number(quantityAddedInput);
  const isQtyValid =
    quantityAddedInput.trim() !== '' &&
    Number.isFinite(parsedQty) &&
    parsedQty > 0;

  const parsedCost = Number(unitPurchaseCostInput);
  const isCostValid =
    unitPurchaseCostInput.trim() !== '' &&
    Number.isFinite(parsedCost) &&
    parsedCost >= 0;

  // Live Calculation Preview (SCR-05, FR-014, BR-006)
  const preview = useMemo(() => {
    if (!activeMaterial) {
      return {
        previousStock: 0,
        newStock: 0,
        totalRestockCost: 0,
        newWeightedCost: 0,
      };
    }

    const previousStock = activeMaterial.currentStock;
    const validQty = isQtyValid ? round2(parsedQty) : 0;
    const validCost = isCostValid
      ? round2(parsedCost)
      : activeMaterial.unitCost;

    const newStock = round2(previousStock + validQty);
    const totalRestockCost = round2(validQty * validCost);
    const newWeightedCost =
      validQty > 0
        ? calculateWeightedAverageCost(
            previousStock,
            activeMaterial.unitCost,
            validQty,
            validCost
          )
        : activeMaterial.unitCost;

    return {
      previousStock,
      newStock,
      totalRestockCost,
      newWeightedCost,
    };
  }, [activeMaterial, isQtyValid, parsedQty, isCostValid, parsedCost]);

  const canSubmit = Boolean(
    activeMaterial && isQtyValid && isCostValid && !isSubmitting
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setShowValidationErrors(true);
    if (!activeMaterial || !isQtyValid || !isCostValid || isSubmitting) {
      return;
    }

    setIsSubmitting(true);
    try {
      await submitStockIn({
        materialId: activeMaterial.id,
        quantityAdded: round2(parsedQty),
        unitPurchaseCost: round2(parsedCost),
        supplierNote: supplierNote.trim(),
      });
      setQuantityAddedInput('');
      setSupplierNote('');
      setShowValidationErrors(false);
    } catch {
      // Domain error is surfaced in StatusBanner via ErpContext
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-5">
      {/* Top Header */}
      <div className="border-b border-[#DCD9D0] pb-4 flex flex-col sm:flex-row sm:items-baseline justify-between gap-2">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
            {t.stockIn.title}
          </h2>
          <p className="text-sm text-[#4A5056] mt-0.5">{t.stockIn.subtitle}</p>
        </div>
        <div className="text-xs font-mono-tabular text-[#6E757C]">
          {t.kpis.inventoryCostValue}:{' '}
          {formatETB(state.summary.inventoryCostValue)}
        </div>
      </div>

      {/* Main Split Workbench (SCR-05: 7 cols Form + 5 cols Recent Ledger on Desktop) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Supplier Restocking Form & Live Calculation Preview */}
        <section
          aria-label={t.stockIn.formHeading}
          className="lg:col-span-7 bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
        >
          <div className="p-4 sm:px-5 border-b border-[#ECEAE3] flex items-center justify-between gap-2">
            <h3 className="text-base font-semibold text-[#14171A] flex items-center gap-2">
              <PackagePlus className="w-4 h-4 text-[#B84A14]" />
              <span>{t.stockIn.formHeading}</span>
            </h3>
            {activeMaterial && (
              <span className="text-xs font-mono-tabular text-[#6E757C]">
                {getCategoryLabel(t, activeMaterial.category, categories)} ·{' '}
                {t.units[activeMaterial.unit]}
              </span>
            )}
          </div>

          <form
            onSubmit={handleSubmit}
            className="p-4 sm:p-5 space-y-4"
            noValidate
          >
            {/* Material Selector */}
            <div>
              <label
                htmlFor="stock-in-material-select"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {t.stockIn.selectMaterialLabel}
              </label>
              <select
                id="stock-in-material-select"
                value={activeMaterial?.id || ''}
                onChange={(e) => setSelectedStockInMaterialId(e.target.value)}
                className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
              >
                {activeMaterials.map((mat) => (
                  <option key={mat.id} value={mat.id}>
                    {mat.name} ({formatQuantity(mat.currentStock)}{' '}
                    {t.units[mat.unit]} · {formatETB(mat.unitCost)})
                  </option>
                ))}
              </select>
            </div>

            {/* Selected Material Current Snapshot */}
            {activeMaterial && (
              <div className="grid grid-cols-2 gap-3 p-3 rounded-md bg-[#F6F5F1] border border-[#DCD9D0]">
                <div>
                  <p className="text-[11px] font-medium text-[#6E757C]">
                    {t.stockIn.currentGroundStockLabel}
                  </p>
                  <p className="text-sm font-bold font-mono-tabular text-[#14171A] mt-0.5">
                    {formatQuantity(activeMaterial.currentStock)}{' '}
                    {t.units[activeMaterial.unit]}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-[11px] font-medium text-[#6E757C]">
                    {t.stockIn.currentWeightedCostLabel}
                  </p>
                  <p className="text-sm font-bold font-mono-tabular text-[#14171A] mt-0.5">
                    {formatETB(activeMaterial.unitCost)} /{' '}
                    {t.units[activeMaterial.unit]}
                  </p>
                </div>
              </div>
            )}

            {/* Quantity Added & Supplier Unit Purchase Cost Inputs */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label
                  htmlFor="stock-in-qty-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.stockIn.quantityAddedLabel}{' '}
                  {activeMaterial ? `(${t.units[activeMaterial.unit]})` : ''}
                </label>
                <input
                  id="stock-in-qty-input"
                  type="number"
                  min="0.01"
                  step="any"
                  required
                  value={quantityAddedInput}
                  onChange={(e) => setQuantityAddedInput(e.target.value)}
                  placeholder={t.stockIn.quantityAddedPlaceholder}
                  className={`w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular rounded-md border bg-[#FFFFFF] text-[#14171A] placeholder:text-[#6E757C] focus:outline-none ${
                    showValidationErrors && !isQtyValid
                      ? 'border-[#B91C1C] bg-[#FEF2F2]'
                      : 'border-[#DCD9D0] focus:border-[#B84A14]'
                  }`}
                />
                {showValidationErrors && !isQtyValid && (
                  <p className="mt-1 text-xs font-medium text-[#B91C1C]">
                    {t.stockIn.invalidQuantityMsg}
                  </p>
                )}
              </div>

              <div>
                <label
                  htmlFor="stock-in-cost-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.stockIn.unitPurchaseCostLabel}
                </label>
                <input
                  id="stock-in-cost-input"
                  type="number"
                  min="0"
                  step="any"
                  required
                  value={unitPurchaseCostInput}
                  onChange={(e) => setUnitPurchaseCostInput(e.target.value)}
                  placeholder={t.stockIn.unitPurchaseCostPlaceholder}
                  className={`w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular rounded-md border bg-[#FFFFFF] text-[#14171A] placeholder:text-[#6E757C] focus:outline-none ${
                    showValidationErrors && !isCostValid
                      ? 'border-[#B91C1C] bg-[#FEF2F2]'
                      : 'border-[#DCD9D0] focus:border-[#B84A14]'
                  }`}
                />
                {showValidationErrors && !isCostValid && (
                  <p className="mt-1 text-xs font-medium text-[#B91C1C]">
                    {t.stockIn.invalidCostMsg}
                  </p>
                )}
              </div>
            </div>

            {/* Optional Supplier / Delivery Note */}
            <div>
              <label
                htmlFor="stock-in-note-input"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {t.stockIn.supplierNoteLabel}
              </label>
              <input
                id="stock-in-note-input"
                type="text"
                maxLength={240}
                value={supplierNote}
                onChange={(e) => setSupplierNote(e.target.value)}
                placeholder={t.stockIn.supplierNotePlaceholder}
                className="w-full min-h-[42px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
              />
            </div>

            {/* Live Calculation Preview Box */}
            {activeMaterial && (
              <div
                aria-label={t.stockIn.previewHeading}
                className="p-4 rounded-md bg-[#ECEAE3] border border-[#DCD9D0] space-y-3"
              >
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold uppercase tracking-wider text-[#14171A]">
                    {t.stockIn.previewHeading}
                  </h4>
                  <span className="text-xs font-mono-tabular text-[#4A5056]">
                    {activeMaterial.name}
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
                  {/* Stock Transition */}
                  <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded p-2.5">
                    <p className="text-[11px] text-[#6E757C]">
                      {t.stockIn.newStockBalanceLabel}
                    </p>
                    <p className="mt-1 text-sm font-bold font-mono-tabular text-[#14171A] flex items-center gap-1.5">
                      <span>{formatQuantity(preview.previousStock)}</span>
                      <ArrowRight className="w-3.5 h-3.5 text-[#B84A14] shrink-0" />
                      <span className="text-[#166534]">
                        {formatQuantity(preview.newStock)}{' '}
                        {t.units[activeMaterial.unit]}
                      </span>
                    </p>
                  </div>

                  {/* Total Restock Cost */}
                  <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded p-2.5">
                    <p className="text-[11px] text-[#6E757C]">
                      {t.stockIn.totalRestockCostLabel}
                    </p>
                    <p className="mt-1 text-sm font-bold font-mono-tabular text-[#14171A]">
                      {formatETB(preview.totalRestockCost)}
                    </p>
                  </div>

                  {/* Updated Weighted-Average Unit Cost */}
                  <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded p-2.5">
                    <p className="text-[11px] text-[#6E757C]">
                      {t.stockIn.updatedWeightedCostLabel}
                    </p>
                    <p className="mt-1 text-sm font-bold font-mono-tabular text-[#B84A14]">
                      {formatETB(preview.newWeightedCost)} /{' '}
                      {t.units[activeMaterial.unit]}
                    </p>
                  </div>
                </div>

                <p className="text-[11px] text-[#4A5056]">
                  {t.stockIn.weightedFormulaNote}
                </p>
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={!canSubmit}
              className="w-full min-h-[48px] px-4 py-3 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center justify-center gap-2 disabled:opacity-45 disabled:cursor-not-allowed"
            >
              <ArrowDownToLine className="w-4 h-4" />
              <span>
                {isSubmitting
                  ? t.stockIn.recordingStockInBtn
                  : t.stockIn.submitStockInBtn}
              </span>
            </button>
          </form>
        </section>

        {/* Right Column: Recent Stock-In Deliveries Ledger */}
        <section
          aria-label={t.stockIn.recentHeading}
          className="lg:col-span-5 bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
        >
          <div className="p-4 sm:px-5 border-b border-[#ECEAE3]">
            <h3 className="text-base font-semibold text-[#14171A]">
              {t.stockIn.recentHeading} ({stockIns.length})
            </h3>
            <p className="text-xs text-[#4A5056] mt-0.5">
              {t.stockIn.recentSubtitle}
            </p>
          </div>

          {stockIns.length === 0 ? (
            <div className="p-8 text-center space-y-2">
              <h4 className="text-sm font-semibold text-[#14171A]">
                {t.stockIn.emptyHistoryTitle}
              </h4>
              <p className="text-xs text-[#4A5056] max-w-sm mx-auto">
                {t.stockIn.emptyHistoryDescription}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-[#ECEAE3] max-h-[600px] overflow-y-auto">
              {stockIns.map((record) => (
                <div
                  key={record.id}
                  className={`p-4 sm:px-5 space-y-2 transition-colors ${
                    record.isReversed
                      ? 'bg-[#FEF2F2]/40 opacity-80'
                      : 'hover:bg-[#F6F5F1]/60'
                  }`}
                >
                  <div className="flex items-baseline justify-between gap-2">
                    <div className="flex items-baseline gap-2">
                      <h4 className="text-sm font-semibold text-[#14171A]">
                        {record.materialName}
                      </h4>
                      {record.isReversed && (
                        <span className="text-[11px] font-bold uppercase text-[#B91C1C]">
                          · REVERSED
                        </span>
                      )}
                    </div>
                    <span
                      className={`text-xs font-bold font-mono-tabular ${
                        record.isReversed
                          ? 'text-[#B91C1C] line-through'
                          : 'text-[#166534]'
                      }`}
                    >
                      +{formatQuantity(record.quantityAdded)}{' '}
                      {t.units[record.unit]}
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-2 pt-1 text-xs font-mono-tabular">
                    <div>
                      <p className="text-[11px] text-[#6E757C]">
                        {t.stockIn.unitCostCol}
                      </p>
                      <p className="font-medium text-[#14171A]">
                        {formatETB(record.unitPurchaseCost)}
                      </p>
                    </div>
                    <div>
                      <p className="text-[11px] text-[#6E757C]">
                        {t.stockIn.totalCostCol}
                      </p>
                      <p className="font-semibold text-[#14171A]">
                        {formatETB(record.totalCost)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-[11px] text-[#6E757C]">
                        {t.stockIn.stockTransitionCol}
                      </p>
                      <p className="font-medium text-[#14171A]">
                        {formatQuantity(record.previousStock)} →{' '}
                        {formatQuantity(record.newStock)} {t.units[record.unit]}
                      </p>
                    </div>
                  </div>

                  {record.isReversed && (
                    <p className="text-[11px] text-[#B91C1C]">
                      Reversed by {record.reversedBy || 'admin'} · Reason:{' '}
                      {record.reversalReason}
                    </p>
                  )}

                  <div className="text-[11px] text-[#6E757C] flex flex-wrap items-center justify-between gap-2 pt-1.5 border-t border-[#ECEAE3]">
                    <span>
                      {record.supplierNote || t.stockIn.supplierNoteFallback} ·{' '}
                      <span className="font-mono-tabular">
                        {new Date(record.createdAt).toLocaleString()}
                      </span>
                    </span>

                    {!record.isReversed && (
                      <button
                        type="button"
                        onClick={() => setStockInToReverse(record)}
                        aria-label={`Reverse stock-in ${record.id}`}
                        className="min-h-[30px] px-2.5 py-1 text-[11px] font-semibold rounded border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] flex items-center gap-1"
                      >
                        <RotateCcw className="w-3 h-3" />
                        <span>Reverse</span>
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* Confirm Stock-In Reversal Dialog */}
      <ConfirmDialog
        isOpen={stockInToReverse !== null}
        title="Reverse Stock-In Delivery"
        recordName={
          stockInToReverse
            ? `${stockInToReverse.materialName} (+${formatQuantity(
                stockInToReverse.quantityAdded
              )} ${t.units[stockInToReverse.unit]})`
            : ''
        }
        description="Completed Stock-In deliveries are never silently deleted. Reversing this delivery will deduct the added quantity from ground stock, restore the previous supplier unit cost, and preserve the original record with your reversal reason."
        confirmLabel="Reverse Stock-In"
        variant="danger"
        requireReason
        reasonLabel="Stock-In Reversal Reason *"
        reasonPlaceholder="e.g., Duplicate entry, supplier delivery returned..."
        onConfirm={async (reason) => {
          if (!stockInToReverse) return;
          await reverseStockIn(stockInToReverse.id, reason);
        }}
        onClose={() => setStockInToReverse(null)}
      />
    </div>
  );
};
