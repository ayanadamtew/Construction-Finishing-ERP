import React, { useEffect, useState } from 'react';
import { AlertTriangle, Lock, X } from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { formatETB, formatQuantity } from '../i18n/translations';
import {
  ALLOWED_CATEGORIES,
  ALLOWED_UNITS,
  Material,
  MaterialCategory,
  MaterialUnit,
} from '../types/erp';
import { AppDomainError } from '../utils/errors';

interface MaterialFormModalProps {
  isOpen: boolean;
  editingMaterial: Material | null;
  onClose: () => void;
}

export const MaterialFormModal: React.FC<MaterialFormModalProps> = ({
  isOpen,
  editingMaterial,
  onClose,
}) => {
  const {
    t,
    createMaterial,
    updateMaterial,
    hasTransactionsForMaterial,
  } = useErpStore();

  const isEditMode = editingMaterial !== null;
  const isUnitLocked =
    isEditMode && hasTransactionsForMaterial(editingMaterial.id);

  const [name, setName] = useState<string>('');
  const [category, setCategory] = useState<MaterialCategory>(
    MaterialCategory.REBAR
  );
  const [specs, setSpecs] = useState<string>('');
  const [unit, setUnit] = useState<MaterialUnit>(MaterialUnit.BARS);
  const [initialStock, setInitialStock] = useState<string>('0');
  const [minStockLevel, setMinStockLevel] = useState<string>('10');
  const [unitCost, setUnitCost] = useState<string>('0');
  const [defaultSellingPrice, setDefaultSellingPrice] = useState<string>('0');

  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  useEffect(() => {
    if (!isOpen) return;
    setFieldErrors({});
    setSubmitError(null);
    setIsSubmitting(false);

    if (editingMaterial) {
      setName(editingMaterial.name);
      setCategory(editingMaterial.category);
      setSpecs(editingMaterial.specs);
      setUnit(editingMaterial.unit);
      setInitialStock(String(editingMaterial.currentStock));
      setMinStockLevel(String(editingMaterial.minStockLevel));
      setUnitCost(String(editingMaterial.unitCost));
      setDefaultSellingPrice(String(editingMaterial.defaultSellingPrice));
    } else {
      setName('');
      setCategory(MaterialCategory.REBAR);
      setSpecs('');
      setUnit(MaterialUnit.BARS);
      setInitialStock('0');
      setMinStockLevel('20');
      setUnitCost('');
      setDefaultSellingPrice('');
    }
  }, [isOpen, editingMaterial]);

  if (!isOpen) return null;

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};
    const trimmedName = name.trim();
    if (trimmedName.length < 1 || trimmedName.length > 120) {
      errors.name = t.catalog.validationNameRequired;
    }

    const parsedMinStock = Number(minStockLevel);
    if (
      minStockLevel.trim() === '' ||
      !Number.isFinite(parsedMinStock) ||
      parsedMinStock < 0
    ) {
      errors.minStockLevel = t.catalog.validationNonNegative;
    }

    const parsedSellingPrice = Number(defaultSellingPrice);
    if (
      defaultSellingPrice.trim() === '' ||
      !Number.isFinite(parsedSellingPrice) ||
      parsedSellingPrice < 0
    ) {
      errors.defaultSellingPrice = t.catalog.validationNonNegative;
    }

    if (!isEditMode) {
      const parsedInitialStock = Number(initialStock);
      if (
        initialStock.trim() === '' ||
        !Number.isFinite(parsedInitialStock) ||
        parsedInitialStock < 0
      ) {
        errors.initialStock = t.catalog.validationNonNegative;
      }

      const parsedUnitCost = Number(unitCost);
      if (
        unitCost.trim() === '' ||
        !Number.isFinite(parsedUnitCost) ||
        parsedUnitCost < 0
      ) {
        errors.unitCost = t.catalog.validationNonNegative;
      }
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    if (!validateForm()) return;

    setIsSubmitting(true);
    try {
      if (isEditMode && editingMaterial) {
        await updateMaterial(editingMaterial.id, {
          name: name.trim(),
          category,
          specs: specs.trim(),
          unit,
          minStockLevel: Number(minStockLevel),
          defaultSellingPrice: Number(defaultSellingPrice),
        });
      } else {
        await createMaterial({
          name: name.trim(),
          category,
          specs: specs.trim(),
          unit,
          initialStock: Number(initialStock),
          minStockLevel: Number(minStockLevel),
          unitCost: Number(unitCost),
          defaultSellingPrice: Number(defaultSellingPrice),
        });
      }
      onClose();
    } catch (err) {
      if (err instanceof AppDomainError) {
        setSubmitError(t.errors[err.code] || err.message);
      } else {
        setSubmitError(
          err instanceof Error ? err.message : t.errors.INTERNAL_ERROR
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-[#14171A]/50 p-0 sm:p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="material-modal-title"
        onClick={(e) => e.stopPropagation()}
        className="w-full sm:max-w-lg max-h-[92vh] overflow-y-auto bg-[#FFFFFF] border border-[#DCD9D0] rounded-t-lg sm:rounded-lg flex flex-col"
      >
        {/* Modal Header */}
        <div className="px-5 py-4 border-b border-[#ECEAE3] flex items-start justify-between gap-3 sticky top-0 bg-[#FFFFFF] z-10">
          <div>
            <h2
              id="material-modal-title"
              className="text-lg font-bold text-[#14171A]"
            >
              {isEditMode
                ? t.catalog.modalEditTitle
                : t.catalog.modalCreateTitle}
            </h2>
            <p className="text-xs text-[#4A5056] mt-0.5">
              {t.catalog.modalSubtitle}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t.catalog.cancelBtn}
            className="min-h-[36px] min-w-[36px] rounded-md flex items-center justify-center text-[#4A5056] hover:bg-[#F6F5F1] hover:text-[#14171A]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Body Form */}
        <form onSubmit={(e) => void handleSubmit(e)} noValidate className="p-5 space-y-4">
          {submitError && (
            <div
              role="alert"
              className="rounded-md border border-[#B91C1C]/30 bg-[#FEF2F2] p-3 text-xs text-[#B91C1C] flex items-start gap-2"
            >
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{submitError}</span>
            </div>
          )}

          {/* 1. Material Name */}
          <div>
            <label
              htmlFor="material-name-input"
              className="block text-xs font-semibold text-[#14171A] mb-1.5"
            >
              {t.catalog.fieldNameLabel} *
            </label>
            <input
              id="material-name-input"
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t.catalog.fieldNamePlaceholder}
              className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
            />
            {fieldErrors.name && (
              <p className="mt-1 text-xs text-[#B91C1C]">{fieldErrors.name}</p>
            )}
          </div>

          {/* 2. Category & Single Tracking Unit */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="material-category-select"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {t.catalog.fieldCategoryLabel} *
              </label>
              <select
                id="material-category-select"
                value={category}
                onChange={(e) =>
                  setCategory(e.target.value as MaterialCategory)
                }
                className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
              >
                {ALLOWED_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {t.categories[cat]}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="material-unit-select"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {t.catalog.fieldUnitLabel} *
              </label>
              <select
                id="material-unit-select"
                value={unit}
                disabled={isUnitLocked}
                onChange={(e) => setUnit(e.target.value as MaterialUnit)}
                className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14] disabled:bg-[#ECEAE3] disabled:text-[#4A5056]"
              >
                {ALLOWED_UNITS.map((u) => (
                  <option key={u} value={u}>
                    {t.units[u]} ({u})
                  </option>
                ))}
              </select>
              {isUnitLocked && (
                <p className="mt-1 text-[11px] text-[#4A5056]">
                  {t.catalog.lockedUnitNotice}
                </p>
              )}
            </div>
          </div>

          {/* 3. Specifications (Optional) */}
          <div>
            <label
              htmlFor="material-specs-input"
              className="block text-xs font-semibold text-[#14171A] mb-1.5"
            >
              {t.catalog.fieldSpecsLabel}
            </label>
            <input
              id="material-specs-input"
              type="text"
              value={specs}
              onChange={(e) => setSpecs(e.target.value)}
              placeholder={t.catalog.fieldSpecsPlaceholder}
              className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
            />
          </div>

          {/* 4. Stock & Low-Stock Threshold */}
          {!isEditMode ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label
                  htmlFor="material-initial-stock-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.catalog.fieldInitialStockLabel} ({t.units[unit]}) *
                </label>
                <input
                  id="material-initial-stock-input"
                  type="number"
                  inputMode="decimal"
                  min="0"
                  step="any"
                  required
                  value={initialStock}
                  onChange={(e) => setInitialStock(e.target.value)}
                  className="w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
                />
                {fieldErrors.initialStock && (
                  <p className="mt-1 text-xs text-[#B91C1C]">
                    {fieldErrors.initialStock}
                  </p>
                )}
              </div>

              <div>
                <label
                  htmlFor="material-min-stock-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.catalog.fieldMinStockLabel} ({t.units[unit]}) *
                </label>
                <input
                  id="material-min-stock-input"
                  type="number"
                  inputMode="decimal"
                  min="0"
                  step="any"
                  required
                  value={minStockLevel}
                  onChange={(e) => setMinStockLevel(e.target.value)}
                  className="w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
                />
                {fieldErrors.minStockLevel && (
                  <p className="mt-1 text-xs text-[#B91C1C]">
                    {fieldErrors.minStockLevel}
                  </p>
                )}
              </div>
            </div>
          ) : (
            /* Edit Mode: FR-004 Read-Only Stock & Cost Display + Editable Min Stock */
            <div className="space-y-3">
              <div className="rounded-md bg-[#ECEAE3] border border-[#DCD9D0] p-3.5 space-y-2">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <p className="text-[11px] font-medium text-[#4A5056] flex items-center gap-1">
                      <Lock className="w-3 h-3" />
                      <span>{t.catalog.fieldCurrentStockReadOnly}</span>
                    </p>
                    <p className="text-sm font-bold font-mono-tabular text-[#14171A] mt-0.5">
                      {formatQuantity(editingMaterial.currentStock)}{' '}
                      {t.units[editingMaterial.unit]}
                    </p>
                  </div>
                  <div>
                    <p className="text-[11px] font-medium text-[#4A5056] flex items-center gap-1">
                      <Lock className="w-3 h-3" />
                      <span>{t.catalog.fieldUnitCostReadOnly}</span>
                    </p>
                    <p className="text-sm font-bold font-mono-tabular text-[#14171A] mt-0.5">
                      {formatETB(editingMaterial.unitCost)}
                    </p>
                  </div>
                </div>
                <p className="text-xs text-[#4A5056]">
                  {t.catalog.immutableStockNotice}
                </p>
              </div>

              <div>
                <label
                  htmlFor="material-min-stock-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.catalog.fieldMinStockLabel} ({t.units[unit]}) *
                </label>
                <input
                  id="material-min-stock-input"
                  type="number"
                  inputMode="decimal"
                  min="0"
                  step="any"
                  required
                  value={minStockLevel}
                  onChange={(e) => setMinStockLevel(e.target.value)}
                  className="w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
                />
                {fieldErrors.minStockLevel && (
                  <p className="mt-1 text-xs text-[#B91C1C]">
                    {fieldErrors.minStockLevel}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* 5. Supplier Unit Purchase Cost & Default Unit Selling Price (ETB) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {!isEditMode && (
              <div>
                <label
                  htmlFor="material-unit-cost-input"
                  className="block text-xs font-semibold text-[#14171A] mb-1.5"
                >
                  {t.catalog.fieldUnitCostLabel} *
                </label>
                <input
                  id="material-unit-cost-input"
                  type="number"
                  inputMode="decimal"
                  min="0"
                  step="any"
                  required
                  placeholder="0.00"
                  value={unitCost}
                  onChange={(e) => setUnitCost(e.target.value)}
                  className="w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
                />
                {fieldErrors.unitCost && (
                  <p className="mt-1 text-xs text-[#B91C1C]">
                    {fieldErrors.unitCost}
                  </p>
                )}
              </div>
            )}

            <div className={isEditMode ? 'sm:col-span-2' : ''}>
              <label
                htmlFor="material-selling-price-input"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {t.catalog.fieldSellingPriceLabel} *
              </label>
              <input
                id="material-selling-price-input"
                type="number"
                inputMode="decimal"
                min="0"
                step="any"
                required
                placeholder="0.00"
                value={defaultSellingPrice}
                onChange={(e) => setDefaultSellingPrice(e.target.value)}
                className="w-full min-h-[44px] px-3 py-2 text-sm font-mono-tabular bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] focus:outline-none focus:border-[#B84A14]"
              />
              {fieldErrors.defaultSellingPrice && (
                <p className="mt-1 text-xs text-[#B91C1C]">
                  {fieldErrors.defaultSellingPrice}
                </p>
              )}
            </div>
          </div>

          {/* Modal Footer Actions */}
          <div className="pt-4 border-t border-[#ECEAE3] flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="min-h-[44px] px-4 py-2.5 text-sm font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors"
            >
              {t.catalog.cancelBtn}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="min-h-[44px] px-5 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors disabled:opacity-50"
            >
              {isSubmitting
                ? t.catalog.savingBtn
                : isEditMode
                ? t.catalog.saveChangesBtn
                : t.catalog.saveNewMaterialBtn}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
