import React, { useMemo, useState } from 'react';
import {
  ArrowDownToLine,
  Edit3,
  Plus,
  Search,
  ShoppingCart,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { formatETB, formatQuantity } from '../i18n/translations';
import {
  ALLOWED_CATEGORIES,
  Material,
  MaterialCategory,
} from '../types/erp';
import { MaterialFormModal } from './MaterialFormModal';

const CATEGORY_TABS: readonly (MaterialCategory | 'all')[] = [
  'all',
  ...ALLOWED_CATEGORIES,
];

export const MaterialsView: React.FC = () => {
  const {
    state,
    t,
    isLoading,
    setActiveTab,
    addToPosCart,
    openStockInForMaterial,
  } = useErpStore();
  const { materials } = state;

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<
    MaterialCategory | 'all'
  >('all');
  const [lowStockOnly, setLowStockOnly] = useState<boolean>(false);

  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingMaterial, setEditingMaterial] = useState<Material | null>(null);

  const filteredMaterials = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return materials.filter((item) => {
      if (selectedCategory !== 'all' && item.category !== selectedCategory) {
        return false;
      }
      if (lowStockOnly && item.currentStock > item.minStockLevel) {
        return false;
      }
      if (!query) return true;
      const inName = item.name.toLowerCase().includes(query);
      const inSpecs = item.specs.toLowerCase().includes(query);
      const inCat = t.categories[item.category].toLowerCase().includes(query);
      return inName || inSpecs || inCat;
    });
  }, [materials, searchQuery, selectedCategory, lowStockOnly, t.categories]);

  const handleOpenCreateModal = () => {
    setEditingMaterial(null);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (material: Material) => {
    setEditingMaterial(material);
    setIsModalOpen(true);
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setSelectedCategory('all');
    setLowStockOnly(false);
  };

  return (
    <div className="space-y-5">
      {/* Top Section Header & Primary Action */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-[#DCD9D0] pb-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
            {t.catalog.title}
          </h2>
          <p className="text-sm text-[#4A5056] mt-0.5">{t.catalog.subtitle}</p>
        </div>

        <button
          type="button"
          onClick={handleOpenCreateModal}
          className="min-h-[44px] px-4 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center justify-center gap-2 shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>{t.catalog.registerMaterialBtn}</span>
        </button>
      </div>

      {/* Search & Interactive Filter Control Bar (FR-005) */}
      <section
        aria-label="Material Catalog Filters"
        className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4 space-y-3"
      >
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-[#6E757C] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="search"
              aria-label={t.catalog.searchPlaceholder}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={t.catalog.searchPlaceholder}
              className="w-full min-h-[44px] pl-10 pr-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
            />
          </div>

          <button
            type="button"
            aria-pressed={lowStockOnly}
            onClick={() => setLowStockOnly((prev) => !prev)}
            className={`min-h-[44px] px-4 py-2 text-xs font-semibold rounded-md border transition-colors shrink-0 ${
              lowStockOnly
                ? 'bg-[#FFF7ED] border-[#9A3412] text-[#9A3412]'
                : 'bg-[#FFFFFF] border-[#DCD9D0] text-[#4A5056] hover:bg-[#F6F5F1] hover:text-[#14171A]'
            }`}
          >
            {t.catalog.lowStockOnlyToggle} ({state.summary.lowStockCount})
          </button>
        </div>

        {/* Category Segmented Filter Buttons */}
        <div className="flex items-center justify-between gap-3 flex-wrap pt-1">
          <div
            role="group"
            aria-label={t.catalog.fieldCategoryLabel}
            className="flex flex-wrap items-center gap-1 p-1 bg-[#ECEAE3] rounded-md"
          >
            {CATEGORY_TABS.map((cat) => {
              const isActive = selectedCategory === cat;
              return (
                <button
                  key={cat}
                  type="button"
                  aria-pressed={isActive}
                  onClick={() => setSelectedCategory(cat)}
                  className={`min-h-[34px] px-3 py-1.5 text-xs font-medium rounded transition-colors ${
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

          <span className="text-xs font-mono-tabular text-[#6E757C]">
            {t.catalog.showingCount}: {filteredMaterials.length} /{' '}
            {materials.length}
          </span>
        </div>
      </section>

      {/* Material Ledger Container */}
      <section
        aria-label="Registered Materials Directory"
        className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
      >
        {isLoading ? (
          <div className="p-6 text-sm text-[#4A5056]">
            {t.shell.loadingState}
          </div>
        ) : materials.length === 0 ? (
          /* Empty Catalog State */
          <div className="p-8 text-center space-y-3">
            <h3 className="text-base font-semibold text-[#14171A]">
              {t.catalog.emptyCatalogTitle}
            </h3>
            <p className="text-sm text-[#4A5056] max-w-md mx-auto">
              {t.catalog.emptyCatalogDescription}
            </p>
            <button
              type="button"
              onClick={handleOpenCreateModal}
              className="min-h-[44px] px-4 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] inline-flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              <span>{t.catalog.registerMaterialBtn}</span>
            </button>
          </div>
        ) : filteredMaterials.length === 0 ? (
          /* Filtered Empty State */
          <div className="p-8 text-center space-y-3">
            <h3 className="text-base font-semibold text-[#14171A]">
              {t.catalog.noMatchesTitle}
            </h3>
            <p className="text-sm text-[#4A5056] max-w-md mx-auto">
              {t.catalog.noMatchesDescription}
            </p>
            <button
              type="button"
              onClick={handleResetFilters}
              className="min-h-[40px] px-4 py-2 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1]"
            >
              {t.catalog.resetFiltersBtn}
            </button>
          </div>
        ) : (
          <div className="divide-y divide-[#ECEAE3]">
            {filteredMaterials.map((item) => {
              const isLowStock = item.currentStock <= item.minStockLevel;
              return (
                <div
                  key={item.id}
                  className="p-4 sm:px-5 flex flex-col lg:flex-row lg:items-center justify-between gap-3 hover:bg-[#F6F5F1]/60 transition-colors"
                >
                  {/* Left: Material Title & Unboxed Middle-Dot Metadata */}
                  <div className="min-w-0 space-y-1">
                    <div className="flex flex-wrap items-baseline gap-2">
                      <h3 className="text-base font-semibold text-[#14171A]">
                        {item.name}
                      </h3>
                      <span aria-hidden="true" className="text-[#6E757C]">
                        ·
                      </span>
                      <span
                        className={`text-xs font-medium ${
                          isLowStock ? 'text-[#9A3412]' : 'text-[#166534]'
                        }`}
                      >
                        {isLowStock
                          ? t.shell.lowStockFlag
                          : t.shell.inStockFlag}
                      </span>
                    </div>

                    <p className="text-xs text-[#4A5056]">
                      <span>{t.categories[item.category]}</span>
                      {item.specs && (
                        <>
                          <span aria-hidden="true"> · </span>
                          <span>{item.specs}</span>
                        </>
                      )}
                      <span aria-hidden="true"> · </span>
                      <span className="font-mono-tabular">
                        {t.shell.minStockCol}: {formatQuantity(item.minStockLevel)}{' '}
                        {t.units[item.unit]}
                      </span>
                    </p>
                  </div>

                  {/* Right: Tabular Numerals & Row Actions */}
                  <div className="flex flex-wrap sm:flex-nowrap items-center justify-between lg:justify-end gap-4 sm:gap-6 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-[#ECEAE3]">
                    <div className="flex items-center gap-4 sm:gap-6 font-mono-tabular text-right">
                      <div>
                        <p className="text-[11px] text-[#6E757C]">
                          {t.shell.costCol}
                        </p>
                        <p className="text-xs font-medium text-[#4A5056]">
                          {formatETB(item.unitCost)}
                        </p>
                      </div>

                      <div>
                        <p className="text-[11px] text-[#6E757C]">
                          {t.shell.priceCol}
                        </p>
                        <p className="text-xs font-semibold text-[#14171A]">
                          {formatETB(item.defaultSellingPrice)}
                        </p>
                      </div>

                      <div className="min-w-[96px]">
                        <p className="text-[11px] text-[#6E757C]">
                          {t.shell.stockCol}
                        </p>
                        <p
                          className={`text-sm font-bold ${
                            isLowStock ? 'text-[#9A3412]' : 'text-[#14171A]'
                          }`}
                        >
                          {formatQuantity(item.currentStock)} {t.units[item.unit]}
                        </p>
                      </div>
                    </div>

                    {/* Row Action Buttons */}
                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        disabled={item.currentStock <= 0}
                        onClick={() => {
                          addToPosCart(item.id);
                          setActiveTab('pos');
                        }}
                        aria-label={`${t.catalog.sellActionBtn} ${item.name}`}
                        className="min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1 disabled:opacity-50"
                      >
                        <ShoppingCart className="w-3.5 h-3.5 text-[#B84A14]" />
                        <span>{t.catalog.sellActionBtn}</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => openStockInForMaterial(item.id)}
                        aria-label={`${t.catalog.stockInActionBtn} ${item.name}`}
                        className="min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1"
                      >
                        <ArrowDownToLine className="w-3.5 h-3.5 text-[#4A5056]" />
                        <span>{t.catalog.stockInActionBtn}</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => handleOpenEditModal(item)}
                        aria-label={`${t.catalog.editMaterialBtn} ${item.name}`}
                        className="min-h-[38px] px-3 py-1.5 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1"
                      >
                        <Edit3 className="w-3.5 h-3.5 text-[#4A5056]" />
                        <span>{t.catalog.editMaterialBtn}</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      <MaterialFormModal
        isOpen={isModalOpen}
        editingMaterial={editingMaterial}
        onClose={() => setIsModalOpen(false)}
      />
    </div>
  );
};
