import React, { useMemo, useState } from 'react';
import {
  Archive,
  ArchiveRestore,
  ArrowDownToLine,
  Edit3,
  FolderCog,
  Plus,
  Search,
  ShoppingCart,
  Trash2,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import {
  formatETB,
  formatQuantity,
  getCategoryLabel,
} from '../i18n/translations';
import { ALLOWED_CATEGORIES, Material } from '../types/erp';
import { ConfirmDialog } from './ConfirmDialog';
import { MaterialFormModal } from './MaterialFormModal';
import { UsersAndCategoriesModal } from './UsersAndCategoriesModal';

export const MaterialsView: React.FC = () => {
  const {
    state,
    t,
    isLoading,
    setActiveTab,
    addToPosCart,
    openStockInForMaterial,
    deleteMaterial,
    setMaterialArchived,
    hasTransactionsForMaterial,
  } = useErpStore();
  const { materials, categories } = state;

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [lowStockOnly, setLowStockOnly] = useState<boolean>(false);
  const [showArchived, setShowArchived] = useState<boolean>(false);

  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingMaterial, setEditingMaterial] = useState<Material | null>(null);
  const [isCategoryModalOpen, setIsCategoryModalOpen] =
    useState<boolean>(false);

  // Delete or Archive Confirmation Modal State
  const [materialToDelete, setMaterialToDelete] = useState<Material | null>(
    null
  );
  const [materialToArchiveToggle, setMaterialToArchiveToggle] =
    useState<Material | null>(null);

  const categoryTabs = useMemo(() => {
    const ids =
      categories && categories.length > 0
        ? categories.map((c) => c.id)
        : [...ALLOWED_CATEGORIES];
    return ['all', ...ids];
  }, [categories]);

  const archivedCount = useMemo(
    () => materials.filter((m) => m.isArchived).length,
    [materials]
  );

  const filteredMaterials = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return materials.filter((item) => {
      if (!showArchived && item.isArchived) {
        return false;
      }
      if (selectedCategory !== 'all' && item.category !== selectedCategory) {
        return false;
      }
      if (lowStockOnly && item.currentStock > item.minStockLevel) {
        return false;
      }
      if (!query) return true;
      const inName = item.name.toLowerCase().includes(query);
      const inSpecs = item.specs.toLowerCase().includes(query);
      const inCat = getCategoryLabel(t, item.category, categories)
        .toLowerCase()
        .includes(query);
      return inName || inSpecs || inCat;
    });
  }, [
    materials,
    showArchived,
    searchQuery,
    selectedCategory,
    lowStockOnly,
    t,
    categories,
  ]);

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
    setShowArchived(false);
  };

  return (
    <div className="space-y-5">
      {/* Top Section Header & Primary Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-[#DCD9D0] pb-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
            {t.catalog.title}
          </h2>
          <p className="text-sm text-[#4A5056] mt-0.5">{t.catalog.subtitle}</p>
        </div>

        <div className="flex flex-wrap items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => setIsCategoryModalOpen(true)}
            className="min-h-[44px] px-3.5 py-2 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors flex items-center gap-1.5"
          >
            <FolderCog className="w-4 h-4 text-[#4A5056]" />
            <span>Categories</span>
          </button>

          <button
            type="button"
            onClick={handleOpenCreateModal}
            className="min-h-[44px] px-4 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center justify-center gap-2"
          >
            <Plus className="w-4 h-4" />
            <span>{t.catalog.registerMaterialBtn}</span>
          </button>
        </div>
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

          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <button
              type="button"
              aria-pressed={lowStockOnly}
              onClick={() => setLowStockOnly((prev) => !prev)}
              className={`min-h-[44px] px-3.5 py-2 text-xs font-semibold rounded-md border transition-colors ${
                lowStockOnly
                  ? 'bg-[#FFF7ED] border-[#9A3412] text-[#9A3412]'
                  : 'bg-[#FFFFFF] border-[#DCD9D0] text-[#4A5056] hover:bg-[#F6F5F1] hover:text-[#14171A]'
              }`}
            >
              {t.catalog.lowStockOnlyToggle} ({state.summary.lowStockCount})
            </button>

            <button
              type="button"
              aria-pressed={showArchived}
              onClick={() => setShowArchived((prev) => !prev)}
              className={`min-h-[44px] px-3.5 py-2 text-xs font-semibold rounded-md border transition-colors flex items-center gap-1.5 ${
                showArchived
                  ? 'bg-[#ECEAE3] border-[#14171A] text-[#14171A]'
                  : 'bg-[#FFFFFF] border-[#DCD9D0] text-[#4A5056] hover:bg-[#F6F5F1] hover:text-[#14171A]'
              }`}
            >
              <Archive className="w-3.5 h-3.5" />
              <span>Archived ({archivedCount})</span>
            </button>
          </div>
        </div>

        {/* Category Segmented Filter Buttons */}
        <div className="flex items-center justify-between gap-3 flex-wrap pt-1">
          <div
            role="group"
            aria-label={t.catalog.fieldCategoryLabel}
            className="flex flex-wrap items-center gap-1 p-1 bg-[#ECEAE3] rounded-md"
          >
            {categoryTabs.map((cat) => {
              const isActive = selectedCategory === cat;
              const label =
                cat === 'all'
                  ? t.categories.all
                  : getCategoryLabel(t, cat, categories);
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
                  {label}
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
              const isLowStock =
                !item.isArchived && item.currentStock <= item.minStockLevel;
              const hasHistory = hasTransactionsForMaterial(item.id);

              return (
                <div
                  key={item.id}
                  className={`p-4 sm:px-5 flex flex-col lg:flex-row lg:items-center justify-between gap-3 transition-colors ${
                    item.isArchived
                      ? 'bg-[#ECEAE3]/50 opacity-80'
                      : 'hover:bg-[#F6F5F1]/60'
                  }`}
                >
                  {/* Left: Material Title & Metadata */}
                  <div className="min-w-0 space-y-1">
                    <div className="flex flex-wrap items-baseline gap-2">
                      <h3 className="text-base font-semibold text-[#14171A]">
                        {item.name}
                      </h3>
                      <span aria-hidden="true" className="text-[#6E757C]">
                        ·
                      </span>
                      {item.isArchived ? (
                        <span className="text-xs font-bold uppercase text-[#6E757C]">
                          Archived (Inactive)
                        </span>
                      ) : (
                        <span
                          className={`text-xs font-medium ${
                            isLowStock ? 'text-[#9A3412]' : 'text-[#166534]'
                          }`}
                        >
                          {isLowStock
                            ? t.shell.lowStockFlag
                            : t.shell.inStockFlag}
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-[#4A5056]">
                      <span>
                        {getCategoryLabel(t, item.category, categories)}
                      </span>
                      {item.specs && (
                        <>
                          <span aria-hidden="true"> · </span>
                          <span>{item.specs}</span>
                        </>
                      )}
                      <span aria-hidden="true"> · </span>
                      <span className="font-mono-tabular">
                        {t.shell.minStockCol}:{' '}
                        {formatQuantity(item.minStockLevel)}{' '}
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
                          {formatQuantity(item.currentStock)}{' '}
                          {t.units[item.unit]}
                        </p>
                      </div>
                    </div>

                    {/* Row Action Buttons */}
                    <div className="flex flex-wrap items-center gap-1.5">
                      {!item.isArchived && (
                        <>
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
                        </>
                      )}

                      <button
                        type="button"
                        onClick={() => handleOpenEditModal(item)}
                        aria-label={`${t.catalog.editMaterialBtn} ${item.name}`}
                        className="min-h-[38px] px-3 py-1.5 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1"
                      >
                        <Edit3 className="w-3.5 h-3.5 text-[#4A5056]" />
                        <span>{t.catalog.editMaterialBtn}</span>
                      </button>

                      {/* Archive / Restore Button (always available, primary path for items with history) */}
                      <button
                        type="button"
                        onClick={() => setMaterialToArchiveToggle(item)}
                        aria-label={`${
                          item.isArchived ? 'Restore' : 'Archive'
                        } ${item.name}`}
                        className="min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#4A5056] hover:text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1"
                      >
                        {item.isArchived ? (
                          <>
                            <ArchiveRestore className="w-3.5 h-3.5 text-[#166534]" />
                            <span>Restore</span>
                          </>
                        ) : (
                          <>
                            <Archive className="w-3.5 h-3.5 text-[#9A3412]" />
                            <span>Archive</span>
                          </>
                        )}
                      </button>

                      {/* Delete Button (permanently deletes unused material; explains rule if history exists) */}
                      {!hasHistory && (
                        <button
                          type="button"
                          onClick={() => setMaterialToDelete(item)}
                          aria-label={`Delete ${item.name}`}
                          className="min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] flex items-center gap-1"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          <span>Delete</span>
                        </button>
                      )}
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

      <UsersAndCategoriesModal
        isOpen={isCategoryModalOpen}
        initialSection="categories"
        onClose={() => setIsCategoryModalOpen(false)}
      />

      {/* Confirm Permanent Delete for Unused Material */}
      <ConfirmDialog
        isOpen={materialToDelete !== null}
        title="Delete Unused Material"
        recordName={materialToDelete ? materialToDelete.name : ''}
        description="This material has never been used in any POS sales, Stock-In deliveries, or Ground-Stock Audits. Confirming will permanently remove it from the catalog."
        confirmLabel="Permanently Delete Material"
        variant="danger"
        onConfirm={async () => {
          if (!materialToDelete) return;
          await deleteMaterial(materialToDelete.id);
        }}
        onClose={() => setMaterialToDelete(null)}
      />

      {/* Confirm Archive / Restore Material */}
      <ConfirmDialog
        isOpen={materialToArchiveToggle !== null}
        title={
          materialToArchiveToggle?.isArchived
            ? 'Restore Archived Material'
            : 'Archive / Deactivate Material'
        }
        recordName={materialToArchiveToggle ? materialToArchiveToggle.name : ''}
        description={
          materialToArchiveToggle?.isArchived
            ? 'Restoring this material will make it active again for POS sales, Stock-In deliveries, and Ground-Stock Audits.'
            : 'Archiving deactivates this material from new POS sales, Stock-In deliveries, and Ground-Stock Audits while keeping all historical ledger records intact.'
        }
        prohibitedExplanation={
          materialToArchiveToggle &&
          hasTransactionsForMaterial(materialToArchiveToggle.id) &&
          !materialToArchiveToggle.isArchived
            ? 'Note: Because this material has transaction history, permanent deletion is prohibited to protect ledger integrity. Archiving is the required safe action.'
            : undefined
        }
        confirmLabel={
          materialToArchiveToggle?.isArchived
            ? 'Restore Material'
            : 'Archive Material'
        }
        variant={materialToArchiveToggle?.isArchived ? 'primary' : 'warning'}
        onConfirm={async () => {
          if (!materialToArchiveToggle) return;
          await setMaterialArchived(
            materialToArchiveToggle.id,
            !materialToArchiveToggle.isArchived
          );
        }}
        onClose={() => setMaterialToArchiveToggle(null)}
      />
    </div>
  );
};
