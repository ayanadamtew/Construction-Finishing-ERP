import React, { useMemo, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Plus,
  Search,
  ShoppingCart,
  Trash2,
  X,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { round2 } from '../domain/inventoryEngine';
import { formatETB, formatQuantity } from '../i18n/translations';
import { ALLOWED_CATEGORIES, MaterialCategory } from '../types/erp';

const CATEGORY_TABS: readonly (MaterialCategory | 'all')[] = [
  'all',
  ...ALLOWED_CATEGORIES,
];

export const SalesPosView: React.FC = () => {
  const {
    state,
    t,
    posCart,
    posCustomerNote,
    setPosCustomerNote,
    addToPosCart,
    updatePosCartQuantity,
    updatePosCartUnitPrice,
    removeFromPosCart,
    clearPosCart,
    submitPosSale,
    lastCompletedSale,
    clearLastCompletedSale,
  } = useErpStore();

  const { materials } = state;

  const [pickerSearch, setPickerSearch] = useState<string>('');
  const [pickerCategory, setPickerCategory] = useState<
    MaterialCategory | 'all'
  >('all');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const filteredPickerMaterials = useMemo(() => {
    const query = pickerSearch.trim().toLowerCase();
    return materials.filter((item) => {
      if (pickerCategory !== 'all' && item.category !== pickerCategory) {
        return false;
      }
      if (!query) return true;
      return (
        item.name.toLowerCase().includes(query) ||
        item.specs.toLowerCase().includes(query) ||
        t.categories[item.category].toLowerCase().includes(query)
      );
    });
  }, [materials, pickerSearch, pickerCategory, t.categories]);

  // Enrich each cart line with live material details, subtotal, remaining stock, and validation flags
  const evaluatedCartLines = useMemo(() => {
    return posCart
      .map((draft) => {
        const material = materials.find((m) => m.id === draft.materialId);
        if (!material) return null;

        const parsedQty = Number(draft.quantityInput);
        const isQtyValid =
          draft.quantityInput.trim() !== '' &&
          Number.isFinite(parsedQty) &&
          parsedQty > 0;

        const parsedPrice = Number(draft.unitPriceInput);
        const isPriceValid =
          draft.unitPriceInput.trim() !== '' &&
          Number.isFinite(parsedPrice) &&
          parsedPrice >= 0;

        const safeQty = isQtyValid ? round2(parsedQty) : 0;
        const safePrice = isPriceValid ? round2(parsedPrice) : 0;

        const isExceedingStock =
          isQtyValid && safeQty > material.currentStock;
        const remainingAfterSale = round2(material.currentStock - safeQty);
        const lineSubtotal = round2(safeQty * safePrice);
        const lineProfit = round2(
          safeQty * (safePrice - material.unitCost)
        );

        return {
          draft,
          material,
          isQtyValid,
          isPriceValid,
          isExceedingStock,
          remainingAfterSale,
          lineSubtotal,
          lineProfit,
        };
      })
      .filter((entry): entry is NonNullable<typeof entry> => entry !== null);
  }, [posCart, materials]);

  const cartTotals = useMemo(() => {
    let totalRevenue = 0;
    let totalProfit = 0;
    let hasValidationError = false;

    for (const line of evaluatedCartLines) {
      totalRevenue = round2(totalRevenue + line.lineSubtotal);
      totalProfit = round2(totalProfit + line.lineProfit);
      if (
        !line.isQtyValid ||
        !line.isPriceValid ||
        line.isExceedingStock
      ) {
        hasValidationError = true;
      }
    }

    return {
      totalRevenue,
      totalProfit,
      hasValidationError,
      canCheckout:
        evaluatedCartLines.length > 0 &&
        !hasValidationError &&
        !isSubmitting,
    };
  }, [evaluatedCartLines, isSubmitting]);

  const handleCheckout = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cartTotals.canCheckout) return;

    setIsSubmitting(true);
    try {
      await submitPosSale();
    } catch {
      // Error is captured in ErpContext and displayed by StatusBanner
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-5">
      {/* Top Section Header */}
      <div className="border-b border-[#DCD9D0] pb-4">
        <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
          {t.pos.title}
        </h2>
        <p className="text-sm text-[#4A5056] mt-0.5">{t.pos.subtitle}</p>
      </div>

      {/* Completed Sale Receipt Card (Success State) */}
      {lastCompletedSale && (
        <section
          aria-label={t.pos.receiptTitle}
          className="bg-[#FFFFFF] border border-[#166534]/40 rounded-lg p-4 sm:p-5 space-y-3"
        >
          <div className="flex items-start justify-between gap-3 border-b border-[#ECEAE3] pb-3">
            <div className="flex items-start gap-2.5">
              <CheckCircle2 className="w-5 h-5 text-[#166534] shrink-0 mt-0.5" />
              <div>
                <h3 className="text-base font-bold text-[#14171A]">
                  {t.pos.receiptTitle}
                </h3>
                <p className="text-xs text-[#4A5056]">
                  {t.pos.receiptSubtitle} ·{' '}
                  <span className="font-mono-tabular">
                    {lastCompletedSale.id}
                  </span>
                  {lastCompletedSale.customerNote &&
                    ` · ${lastCompletedSale.customerNote}`}
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={clearLastCompletedSale}
              aria-label={t.pos.dismissReceiptBtn}
              className="min-h-[34px] px-2.5 py-1 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#4A5056] hover:text-[#14171A] flex items-center gap-1"
            >
              <X className="w-3.5 h-3.5" />
              <span>{t.pos.dismissReceiptBtn}</span>
            </button>
          </div>

          <div className="divide-y divide-[#ECEAE3]">
            {lastCompletedSale.items.map((item) => (
              <div
                key={item.materialId}
                className="py-2 flex items-center justify-between gap-3 text-xs"
              >
                <div>
                  <span className="font-semibold text-[#14171A]">
                    {item.materialName}
                  </span>
                  <span className="text-[#4A5056] font-mono-tabular">
                    {' '}
                    · {formatQuantity(item.quantity)} {t.units[item.unit]} ×{' '}
                    {formatETB(item.unitSellingPrice)}
                  </span>
                </div>
                <span className="font-bold font-mono-tabular text-[#14171A]">
                  {formatETB(item.lineTotal)}
                </span>
              </div>
            ))}
          </div>

          <div className="pt-2 border-t border-[#ECEAE3] flex flex-wrap items-center justify-between gap-3 font-mono-tabular">
            <span className="text-xs text-[#166534] font-semibold">
              {t.pos.estimatedProfitLabel}:{' '}
              {formatETB(lastCompletedSale.totalProfit)}
            </span>
            <span className="text-base font-bold text-[#14171A]">
              {t.pos.totalRevenueLabel}:{' '}
              {formatETB(lastCompletedSale.totalRevenue)}
            </span>
          </div>
        </section>
      )}

      {/* 2-Column POS Workbench (Desktop Split / Mobile Stacked) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* LEFT COLUMN (5 cols on Desktop): Material Picker */}
        <section
          aria-label={t.pos.pickerHeading}
          className="lg:col-span-5 bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
        >
          <div className="p-4 border-b border-[#ECEAE3] space-y-3">
            <h3 className="text-sm font-bold text-[#14171A]">
              {t.pos.pickerHeading}
            </h3>

            <div className="relative">
              <Search className="w-4 h-4 text-[#6E757C] absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="search"
                aria-label={t.pos.pickerSearchPlaceholder}
                value={pickerSearch}
                onChange={(e) => setPickerSearch(e.target.value)}
                placeholder={t.pos.pickerSearchPlaceholder}
                className="w-full min-h-[40px] pl-9 pr-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
              />
            </div>

            <div
              role="group"
              aria-label={t.catalog.fieldCategoryLabel}
              className="flex flex-wrap items-center gap-1 p-1 bg-[#ECEAE3] rounded-md"
            >
              {CATEGORY_TABS.map((cat) => {
                const isActive = pickerCategory === cat;
                return (
                  <button
                    key={cat}
                    type="button"
                    aria-pressed={isActive}
                    onClick={() => setPickerCategory(cat)}
                    className={`min-h-[30px] px-2.5 py-1 text-[11px] font-medium rounded transition-colors ${
                      isActive
                        ? 'bg-[#FFFFFF] text-[#14171A] font-semibold'
                        : 'text-[#4A5056] hover:text-[#14171A]'
                    }`}
                  >
                    {t.categories[cat]}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="divide-y divide-[#ECEAE3] max-h-[540px] overflow-y-auto">
            {filteredPickerMaterials.map((item) => {
              const isOutOfStock = item.currentStock <= 0;
              const inCartLine = posCart.find(
                (line) => line.materialId === item.id
              );

              return (
                <div
                  key={item.id}
                  className="p-3.5 flex items-center justify-between gap-3 hover:bg-[#F6F5F1]/60 transition-colors"
                >
                  <div className="min-w-0">
                    <h4 className="text-sm font-semibold text-[#14171A] truncate">
                      {item.name}
                    </h4>
                    <p className="text-xs text-[#4A5056] font-mono-tabular mt-0.5">
                      {formatETB(item.defaultSellingPrice)} / {t.units[item.unit]}{' '}
                      ·{' '}
                      <span
                        className={
                          isOutOfStock
                            ? 'text-[#B91C1C] font-semibold'
                            : item.currentStock <= item.minStockLevel
                            ? 'text-[#9A3412] font-semibold'
                            : 'text-[#166534] font-semibold'
                        }
                      >
                        {isOutOfStock
                          ? t.pos.outOfStockLabel
                          : `${t.pos.availableLabel}: ${formatQuantity(
                              item.currentStock
                            )} ${t.units[item.unit]}`}
                      </span>
                    </p>
                  </div>

                  <button
                    type="button"
                    disabled={isOutOfStock}
                    onClick={() => addToPosCart(item.id)}
                    aria-label={`${t.pos.addBtn} ${item.name}`}
                    className={`min-h-[40px] px-3 py-1.5 text-xs font-semibold rounded-md flex items-center gap-1.5 shrink-0 transition-colors ${
                      isOutOfStock
                        ? 'bg-[#ECEAE3] text-[#6E757C] cursor-not-allowed'
                        : inCartLine
                        ? 'bg-[#14171A] text-[#FFFFFF] hover:bg-[#14171A]/90'
                        : 'bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E]'
                    }`}
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>
                      {inCartLine ? t.pos.inCartBtn : t.pos.addBtn}
                    </span>
                  </button>
                </div>
              );
            })}
          </div>
        </section>

        {/* RIGHT COLUMN (7 cols on Desktop): Active Multi-Item Sale Receipt Cart */}
        <section
          aria-label={t.pos.cartHeading}
          className="lg:col-span-7 bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
        >
          <div className="p-4 border-b border-[#ECEAE3] flex items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <ShoppingCart className="w-4 h-4 text-[#B84A14]" />
              <h3 className="text-sm font-bold text-[#14171A]">
                {t.pos.cartHeading} ({evaluatedCartLines.length})
              </h3>
            </div>

            {evaluatedCartLines.length > 0 && (
              <button
                type="button"
                onClick={clearPosCart}
                disabled={isSubmitting}
                className="min-h-[34px] px-3 py-1 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] transition-colors"
              >
                {t.pos.clearCartBtn}
              </button>
            )}
          </div>

          {evaluatedCartLines.length === 0 ? (
            /* Empty Cart State */
            <div className="p-10 text-center space-y-2">
              <h4 className="text-base font-semibold text-[#14171A]">
                {t.pos.emptyCartTitle}
              </h4>
              <p className="text-sm text-[#4A5056] max-w-md mx-auto">
                {t.pos.emptyCartDescription}
              </p>
            </div>
          ) : (
            <form onSubmit={(e) => void handleCheckout(e)} noValidate>
              <div className="divide-y divide-[#ECEAE3]">
                {evaluatedCartLines.map((line) => {
                  const {
                    draft,
                    material,
                    isQtyValid,
                    isPriceValid,
                    isExceedingStock,
                    remainingAfterSale,
                    lineSubtotal,
                  } = line;

                  const qtyInputId = `pos-qty-${material.id}`;
                  const priceInputId = `pos-price-${material.id}`;

                  return (
                    <div
                      key={material.id}
                      className={`p-4 space-y-3 transition-colors ${
                        isExceedingStock || !isQtyValid || !isPriceValid
                          ? 'bg-[#FEF2F2]/60'
                          : ''
                      }`}
                    >
                      {/* Line Header */}
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <h4 className="text-sm font-bold text-[#14171A]">
                            {material.name}
                          </h4>
                          <p className="text-xs text-[#4A5056] font-mono-tabular">
                            {t.categories[material.category]} ·{' '}
                            {t.pos.availableLabel}:{' '}
                            {formatQuantity(material.currentStock)}{' '}
                            {t.units[material.unit]} · {t.shell.costCol}:{' '}
                            {formatETB(material.unitCost)}
                          </p>
                        </div>

                        <button
                          type="button"
                          onClick={() => removeFromPosCart(material.id)}
                          aria-label={`${t.pos.removeLineBtn} ${material.name}`}
                          className="min-h-[36px] min-w-[36px] rounded-md flex items-center justify-center text-[#B91C1C] hover:bg-[#FEF2F2]"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                      {/* Quantity & Unit Selling Price Inputs */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label
                            htmlFor={qtyInputId}
                            className="block text-xs font-semibold text-[#14171A] mb-1"
                          >
                            {t.pos.quantitySoldLabel} ({t.units[material.unit]}) *
                          </label>
                          <input
                            id={qtyInputId}
                            type="number"
                            inputMode="decimal"
                            min="0.01"
                            max={material.currentStock}
                            step="any"
                            value={draft.quantityInput}
                            onChange={(e) =>
                              updatePosCartQuantity(
                                material.id,
                                e.target.value
                              )
                            }
                            className={`w-full min-h-[42px] px-3 py-1.5 text-sm font-mono-tabular bg-[#FFFFFF] border rounded-md text-[#14171A] focus:outline-none ${
                              isExceedingStock || !isQtyValid
                                ? 'border-[#B91C1C] focus:border-[#B91C1C]'
                                : 'border-[#DCD9D0] focus:border-[#B84A14]'
                            }`}
                          />
                        </div>

                        <div>
                          <label
                            htmlFor={priceInputId}
                            className="block text-xs font-semibold text-[#14171A] mb-1"
                          >
                            {t.pos.unitSellingPriceLabel} *
                          </label>
                          <input
                            id={priceInputId}
                            type="number"
                            inputMode="decimal"
                            min="0"
                            step="any"
                            value={draft.unitPriceInput}
                            onChange={(e) =>
                              updatePosCartUnitPrice(
                                material.id,
                                e.target.value
                              )
                            }
                            className={`w-full min-h-[42px] px-3 py-1.5 text-sm font-mono-tabular bg-[#FFFFFF] border rounded-md text-[#14171A] focus:outline-none ${
                              !isPriceValid
                                ? 'border-[#B91C1C] focus:border-[#B91C1C]'
                                : 'border-[#DCD9D0] focus:border-[#B84A14]'
                            }`}
                          />
                        </div>
                      </div>

                      {/* Strict Stock Floor Guard Alert (FR-011, BR-002) */}
                      {isExceedingStock && (
                        <div
                          role="alert"
                          className="rounded-md border border-[#B91C1C]/40 bg-[#FEF2F2] p-2.5 text-xs text-[#B91C1C] flex items-start gap-2"
                        >
                          <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                          <span>
                            {t.pos.stockFloorBlockedMsg} (
                            {t.pos.availableLabel}:{' '}
                            {formatQuantity(material.currentStock)}{' '}
                            {t.units[material.unit]})
                          </span>
                        </div>
                      )}

                      {!isQtyValid && (
                        <p className="text-xs text-[#B91C1C]">
                          {t.pos.invalidQuantityMsg}
                        </p>
                      )}

                      {!isPriceValid && (
                        <p className="text-xs text-[#B91C1C]">
                          {t.pos.invalidPriceMsg}
                        </p>
                      )}

                      {/* Live Line Subtotal & Remaining Stock Preview (FR-009) */}
                      <div className="pt-2 border-t border-[#ECEAE3] flex flex-wrap items-center justify-between gap-2 text-xs font-mono-tabular">
                        <span
                          className={
                            isExceedingStock
                              ? 'text-[#B91C1C] font-semibold'
                              : 'text-[#4A5056]'
                          }
                        >
                          {t.pos.remainingAfterSaleLabel}:{' '}
                          <strong className="font-bold">
                            {formatQuantity(Math.max(0, remainingAfterSale))}{' '}
                            {t.units[material.unit]}
                          </strong>
                        </span>

                        <span className="text-sm font-bold text-[#14171A]">
                          {t.pos.lineSubtotalLabel}: {formatETB(lineSubtotal)}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Optional Customer Note & Sticky Checkout Summary Footer */}
              <div className="p-4 bg-[#ECEAE3]/60 border-t border-[#DCD9D0] space-y-4">
                <div>
                  <label
                    htmlFor="pos-customer-note-input"
                    className="block text-xs font-semibold text-[#14171A] mb-1"
                  >
                    {t.pos.customerNoteLabel}
                  </label>
                  <input
                    id="pos-customer-note-input"
                    type="text"
                    value={posCustomerNote}
                    onChange={(e) => setPosCustomerNote(e.target.value)}
                    placeholder={t.pos.customerNotePlaceholder}
                    className="w-full min-h-[42px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
                  />
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2 border-t border-[#DCD9D0]">
                  <div className="space-y-0.5 font-mono-tabular">
                    <p className="text-xs text-[#4A5056]">
                      {t.pos.totalItemsLabel}: {evaluatedCartLines.length} ·{' '}
                      {t.pos.estimatedProfitLabel}:{' '}
                      <span className="text-[#166534] font-semibold">
                        {formatETB(cartTotals.totalProfit)}
                      </span>
                    </p>
                    <p className="text-lg font-bold text-[#14171A]">
                      {t.pos.totalRevenueLabel}:{' '}
                      {formatETB(cartTotals.totalRevenue)}
                    </p>
                  </div>

                  <button
                    type="submit"
                    disabled={!cartTotals.canCheckout}
                    className="min-h-[48px] px-5 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors disabled:bg-[#D6D3CD] disabled:text-[#78756F] disabled:cursor-not-allowed"
                  >
                    {isSubmitting
                      ? t.pos.processingSaleBtn
                      : t.pos.completeSaleBtn}
                  </button>
                </div>
              </div>
            </form>
          )}
        </section>
      </div>
    </div>
  );
};
