import React, { useMemo, useState } from 'react';
import {
  ArrowRight,
  Check,
  ClipboardCheck,
  History,
  RotateCcw,
  Search,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { round2 } from '../domain/inventoryEngine';
import { formatETB, formatQuantity } from '../i18n/translations';
import {
  ALLOWED_CATEGORIES,
  MaterialCategory,
  SaleTransaction,
  StockAuditRecord,
  StockInRecord,
} from '../types/erp';

type SubViewMode = 'ground-audit' | 'history-ledger';
type LedgerFilterType = 'all' | 'sales' | 'stock-in' | 'audits';

const CATEGORY_TABS: readonly (MaterialCategory | 'all')[] = [
  'all',
  ...ALLOWED_CATEGORIES,
];

interface UnifiedLedgerItem {
  id: string;
  kind: 'sale' | 'stock-in' | 'audit';
  createdAt: string;
  sale?: SaleTransaction;
  stockIn?: StockInRecord;
  audit?: StockAuditRecord;
}

export const AuditAndLogView: React.FC = () => {
  const { state, t, submitStockAudit } = useErpStore();
  const { materials, sales, stockIns, audits } = state;

  const [subView, setSubView] = useState<SubViewMode>('ground-audit');

  // SCR-06: Ground-Stock Audit Worksheet State
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<
    MaterialCategory | 'all'
  >('all');
  const [auditNote, setAuditNote] = useState<string>('');
  const [physicalCounts, setPhysicalCounts] = useState<Record<string, string>>(
    {}
  );
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  // SCR-07: History Ledger Filter State
  const [ledgerFilter, setLedgerFilter] = useState<LedgerFilterType>('all');
  const [ledgerSearch, setLedgerSearch] = useState<string>('');

  const filteredMaterials = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return materials.filter((item) => {
      if (selectedCategory !== 'all' && item.category !== selectedCategory) {
        return false;
      }
      if (!query) return true;
      return (
        item.name.toLowerCase().includes(query) ||
        item.specs.toLowerCase().includes(query) ||
        t.categories[item.category].toLowerCase().includes(query)
      );
    });
  }, [materials, selectedCategory, searchQuery, t.categories]);

  // Evaluate all entered counts across the entire catalog (BR-008)
  const auditEvaluation = useMemo(() => {
    let countedCount = 0;
    let varianceCount = 0;
    let hasInvalidEntry = false;
    const validItems: Array<{ materialId: string; physicalCount: number }> = [];

    for (const mat of materials) {
      const raw = physicalCounts[mat.id];
      if (raw === undefined || raw.trim() === '') {
        continue;
      }
      countedCount += 1;
      const parsed = Number(raw);
      if (!Number.isFinite(parsed) || parsed < 0) {
        hasInvalidEntry = true;
        continue;
      }
      const roundedCount = round2(parsed);
      const variance = round2(roundedCount - mat.currentStock);
      if (variance !== 0) {
        varianceCount += 1;
      }
      validItems.push({
        materialId: mat.id,
        physicalCount: roundedCount,
      });
    }

    return {
      countedCount,
      varianceCount,
      hasInvalidEntry,
      validItems,
      canCommit:
        validItems.length > 0 && !hasInvalidEntry && !isSubmitting,
    };
  }, [materials, physicalCounts, isSubmitting]);

  const handleCountChange = (materialId: string, value: string) => {
    setPhysicalCounts((prev) => ({
      ...prev,
      [materialId]: value,
    }));
  };

  const handleClearCounts = () => {
    setPhysicalCounts({});
    setAuditNote('');
  };

  const handleCommitAudit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auditEvaluation.canCommit) return;

    setIsSubmitting(true);
    try {
      await submitStockAudit({
        note: auditNote.trim(),
        items: auditEvaluation.validItems,
      });
      setPhysicalCounts({});
      setAuditNote('');
    } catch {
      // Domain error is surfaced in StatusBanner via ErpContext
    } finally {
      setIsSubmitting(false);
    }
  };

  // SCR-07: Chronological Unified Ledger (Sales, Stock-Ins, Audits)
  const unifiedLedger = useMemo<UnifiedLedgerItem[]>(() => {
    const list: UnifiedLedgerItem[] = [];

    if (ledgerFilter === 'all' || ledgerFilter === 'sales') {
      for (const s of sales) {
        list.push({
          id: s.id,
          kind: 'sale',
          createdAt: s.createdAt,
          sale: s,
        });
      }
    }

    if (ledgerFilter === 'all' || ledgerFilter === 'stock-in') {
      for (const st of stockIns) {
        list.push({
          id: st.id,
          kind: 'stock-in',
          createdAt: st.createdAt,
          stockIn: st,
        });
      }
    }

    if (ledgerFilter === 'all' || ledgerFilter === 'audits') {
      for (const a of audits) {
        list.push({
          id: a.id,
          kind: 'audit',
          createdAt: a.createdAt,
          audit: a,
        });
      }
    }

    const query = ledgerSearch.trim().toLowerCase();
    const filtered = query
      ? list.filter((entry) => {
          if (entry.sale) {
            const inNote = entry.sale.customerNote.toLowerCase().includes(query);
            const inItems = entry.sale.items.some((i) =>
              i.materialName.toLowerCase().includes(query)
            );
            return inNote || inItems || entry.sale.id.toLowerCase().includes(query);
          }
          if (entry.stockIn) {
            return (
              entry.stockIn.materialName.toLowerCase().includes(query) ||
              entry.stockIn.supplierNote.toLowerCase().includes(query) ||
              entry.stockIn.id.toLowerCase().includes(query)
            );
          }
          if (entry.audit) {
            const inNote = entry.audit.note.toLowerCase().includes(query);
            const inAdj = entry.audit.adjustments.some((adj) =>
              adj.materialName.toLowerCase().includes(query)
            );
            return inNote || inAdj || entry.audit.id.toLowerCase().includes(query);
          }
          return false;
        })
      : list;

    return filtered.sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }, [sales, stockIns, audits, ledgerFilter, ledgerSearch]);

  const totalLedgerCount = sales.length + stockIns.length + audits.length;

  return (
    <div className="space-y-5">
      {/* Top Header & Sub-Tab Mode Switcher (SCR-06 vs SCR-07) */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 border-b border-[#DCD9D0] pb-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
            {t.auditLog.title}
          </h2>
          <p className="text-sm text-[#4A5056] mt-0.5">{t.auditLog.subtitle}</p>
        </div>

        {/* Interactive Segmented Mode Switcher */}
        <div
          role="group"
          aria-label={t.auditLog.title}
          className="inline-flex items-center p-1 bg-[#ECEAE3] border border-[#DCD9D0] rounded-md shrink-0 self-start lg:self-auto"
        >
          <button
            type="button"
            aria-pressed={subView === 'ground-audit'}
            onClick={() => setSubView('ground-audit')}
            className={`min-h-[38px] px-3.5 py-1.5 text-xs font-semibold rounded transition-colors flex items-center gap-1.5 ${
              subView === 'ground-audit'
                ? 'bg-[#B84A14] text-[#FFFFFF]'
                : 'text-[#4A5056] hover:text-[#14171A]'
            }`}
          >
            <ClipboardCheck className="w-3.5 h-3.5" />
            <span>{t.auditLog.tabGroundAudit}</span>
          </button>

          <button
            type="button"
            aria-pressed={subView === 'history-ledger'}
            onClick={() => setSubView('history-ledger')}
            className={`min-h-[38px] px-3.5 py-1.5 text-xs font-semibold rounded transition-colors flex items-center gap-1.5 ${
              subView === 'history-ledger'
                ? 'bg-[#B84A14] text-[#FFFFFF]'
                : 'text-[#4A5056] hover:text-[#14171A]'
            }`}
          >
            <History className="w-3.5 h-3.5" />
            <span>
              {t.auditLog.tabHistoryLedger} ({totalLedgerCount})
            </span>
          </button>
        </div>
      </div>

      {subView === 'ground-audit' ? (
        /* ====================================================================
         * SCR-06: Physical Ground-Stock Audit & Reconciliation Worksheet
         * ==================================================================== */
        <form onSubmit={handleCommitAudit} className="space-y-5" noValidate>
          {/* Audit Control Bar: Search, Category Filter, Audit Note, & Live Counters */}
          <section
            aria-label={t.auditLog.tabGroundAudit}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4 space-y-4"
          >
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-3">
              {/* Material Search */}
              <div className="lg:col-span-5 relative">
                <Search className="w-4 h-4 text-[#6E757C] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  type="search"
                  aria-label={t.auditLog.searchPlaceholder}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder={t.auditLog.searchPlaceholder}
                  className="w-full min-h-[42px] pl-10 pr-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
                />
              </div>

              {/* Audit Reason / Yard Note */}
              <div className="lg:col-span-7">
                <input
                  id="ground-audit-note-input"
                  type="text"
                  maxLength={250}
                  aria-label={t.auditLog.auditNoteLabel}
                  value={auditNote}
                  onChange={(e) => setAuditNote(e.target.value)}
                  placeholder={t.auditLog.auditNotePlaceholder}
                  className="w-full min-h-[42px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
                />
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-between gap-3 pt-1">
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
                      className={`min-h-[32px] px-2.5 py-1 text-xs font-medium rounded transition-colors ${
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

              <div className="text-xs font-mono-tabular text-[#4A5056]">
                <span>
                  {t.auditLog.countedSummaryLabel}:{' '}
                  <strong className="text-[#14171A]">
                    {auditEvaluation.countedCount}
                  </strong>
                </span>
                <span aria-hidden="true"> · </span>
                <span>
                  {t.auditLog.variancesDetectedLabel}:{' '}
                  <strong
                    className={
                      auditEvaluation.varianceCount > 0
                        ? 'text-[#9A3412]'
                        : 'text-[#166534]'
                    }
                  >
                    {auditEvaluation.varianceCount}
                  </strong>
                </span>
              </div>
            </div>
          </section>

          {/* Audit Worksheet Rows */}
          <section
            aria-label="Ground-Stock Audit Worksheet"
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
          >
            <div className="divide-y divide-[#ECEAE3]">
              {filteredMaterials.map((mat) => {
                const rawInput = physicalCounts[mat.id] ?? '';
                const hasEntry = rawInput.trim() !== '';
                const parsedCount = Number(rawInput);
                const isEntryValid =
                  !hasEntry ||
                  (Number.isFinite(parsedCount) && parsedCount >= 0);

                const roundedPhysical =
                  hasEntry && isEntryValid ? round2(parsedCount) : null;
                const variance =
                  roundedPhysical !== null
                    ? round2(roundedPhysical - mat.currentStock)
                    : null;
                const costImpact =
                  variance !== null ? round2(variance * mat.unitCost) : null;

                return (
                  <div
                    key={mat.id}
                    className={`p-4 sm:px-5 flex flex-col lg:flex-row lg:items-center justify-between gap-4 transition-colors ${
                      !isEntryValid
                        ? 'bg-[#FEF2F2]/60'
                        : hasEntry
                          ? 'bg-[#F6F5F1]/80'
                          : 'hover:bg-[#F6F5F1]/40'
                    }`}
                  >
                    {/* Left: Material Identity & Expected App Stock */}
                    <div className="min-w-0 space-y-1 flex-1">
                      <div className="flex flex-wrap items-baseline gap-2">
                        <h3 className="text-sm sm:text-base font-semibold text-[#14171A]">
                          {mat.name}
                        </h3>
                        <span aria-hidden="true" className="text-[#6E757C]">
                          ·
                        </span>
                        <span className="text-xs text-[#4A5056]">
                          {t.categories[mat.category]}
                        </span>
                      </div>
                      <p className="text-xs text-[#6E757C]">
                        {mat.specs} · {t.shell.costCol}:{' '}
                        <span className="font-mono-tabular">
                          {formatETB(mat.unitCost)}
                        </span>
                      </p>
                    </div>

                    {/* Right: Expected Stock, Physical Ground Count Input, & Live Variance */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-5 items-center lg:w-[620px] shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-[#ECEAE3]">
                      {/* 1. Expected App Stock */}
                      <div className="sm:text-right font-mono-tabular">
                        <p className="text-[11px] text-[#6E757C]">
                          {t.auditLog.expectedStockCol}
                        </p>
                        <p className="text-sm font-bold text-[#14171A]">
                          {formatQuantity(mat.currentStock)} {t.units[mat.unit]}
                        </p>
                      </div>

                      {/* 2. Physical Ground Count Input + 1-Tap Match (=) */}
                      <div>
                        <label
                          htmlFor={`audit-count-${mat.id}`}
                          className="block text-[11px] font-medium text-[#4A5056] mb-1"
                        >
                          {t.auditLog.physicalCountCol} ({t.units[mat.unit]})
                        </label>
                        <div className="flex items-center gap-1.5">
                          <input
                            id={`audit-count-${mat.id}`}
                            type="number"
                            min="0"
                            step="any"
                            value={rawInput}
                            onChange={(e) =>
                              handleCountChange(mat.id, e.target.value)
                            }
                            placeholder={String(mat.currentStock)}
                            className={`w-full min-h-[40px] px-2.5 py-1.5 text-sm font-mono-tabular rounded border bg-[#FFFFFF] text-[#14171A] placeholder:text-[#6E757C]/60 focus:outline-none ${
                              !isEntryValid
                                ? 'border-[#B91C1C] bg-[#FEF2F2]'
                                : hasEntry
                                  ? 'border-[#B84A14]'
                                  : 'border-[#DCD9D0] focus:border-[#B84A14]'
                            }`}
                          />
                          <button
                            type="button"
                            onClick={() =>
                              handleCountChange(
                                mat.id,
                                String(mat.currentStock)
                              )
                            }
                            title={t.auditLog.matchBtnLabel}
                            aria-label={`${t.auditLog.matchBtnLabel} ${mat.name}`}
                            className="min-h-[40px] px-2.5 py-1.5 text-xs font-mono-tabular font-semibold rounded border border-[#DCD9D0] bg-[#ECEAE3] text-[#14171A] hover:bg-[#DCD9D0] shrink-0"
                          >
                            =
                          </button>
                        </div>
                      </div>

                      {/* 3. Live Variance Display (FR-018) */}
                      <div className="sm:text-right font-mono-tabular">
                        <p className="text-[11px] text-[#6E757C]">
                          {t.auditLog.varianceCol}
                        </p>
                        {!hasEntry ? (
                          <p className="text-xs text-[#6E757C]">
                            {t.auditLog.untouchedLabel}
                          </p>
                        ) : !isEntryValid ? (
                          <p className="text-xs font-semibold text-[#B91C1C]">
                            {t.auditLog.invalidPhysicalCountMsg}
                          </p>
                        ) : variance === 0 ? (
                          <p className="text-xs font-semibold text-[#166534] inline-flex items-center gap-1 sm:justify-end">
                            <Check className="w-3.5 h-3.5" />
                            <span>
                              0 {t.units[mat.unit]} ({t.auditLog.exactMatchLabel})
                            </span>
                          </p>
                        ) : variance !== null && variance > 0 ? (
                          <div>
                            <p className="text-xs font-bold text-[#9A3412]">
                              +{formatQuantity(variance)} {t.units[mat.unit]} (
                              {t.auditLog.surplusLabel})
                            </p>
                            {costImpact !== null && (
                              <p className="text-[11px] text-[#4A5056]">
                                +{formatETB(costImpact)}
                              </p>
                            )}
                          </div>
                        ) : (
                          <div>
                            <p className="text-xs font-bold text-[#B91C1C]">
                              {formatQuantity(variance ?? 0)} {t.units[mat.unit]}{' '}
                              ({t.auditLog.shortageLabel})
                            </p>
                            {costImpact !== null && (
                              <p className="text-[11px] text-[#B91C1C]">
                                {formatETB(costImpact)}
                              </p>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Audit Commit Footer */}
            <div className="p-4 sm:px-5 bg-[#ECEAE3] border-t border-[#DCD9D0] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="text-xs font-mono-tabular text-[#14171A]">
                <span>
                  {t.auditLog.countedSummaryLabel}:{' '}
                  <strong>{auditEvaluation.countedCount}</strong> /{' '}
                  {materials.length}
                </span>
                <span aria-hidden="true"> · </span>
                <span>
                  {t.auditLog.variancesDetectedLabel}:{' '}
                  <strong>{auditEvaluation.varianceCount}</strong>
                </span>
              </div>

              <div className="flex flex-wrap items-center gap-2.5">
                {auditEvaluation.countedCount > 0 && (
                  <button
                    type="button"
                    onClick={handleClearCounts}
                    className="min-h-[44px] px-3.5 py-2 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1.5"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>{t.auditLog.clearCountsBtn}</span>
                  </button>
                )}

                <button
                  type="submit"
                  disabled={!auditEvaluation.canCommit}
                  className="min-h-[44px] px-5 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center justify-center gap-2 disabled:opacity-45 disabled:cursor-not-allowed"
                >
                  <ClipboardCheck className="w-4 h-4" />
                  <span>
                    {isSubmitting
                      ? t.auditLog.committingAuditBtn
                      : t.auditLog.commitAuditBtn}
                  </span>
                </button>
              </div>
            </div>
          </section>
        </form>
      ) : (
        /* ====================================================================
         * SCR-07: Immutable Transaction & Audit History Ledger (FR-021, BR-007)
         * ==================================================================== */
        <div className="space-y-4">
          {/* Filter & Search Bar */}
          <section
            aria-label={t.auditLog.tabHistoryLedger}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
          >
            <div
              role="group"
              aria-label="Ledger Type Filter"
              className="flex flex-wrap items-center gap-1 p-1 bg-[#ECEAE3] rounded-md"
            >
              {(
                [
                  { id: 'all', label: `${t.auditLog.filterAll} (${totalLedgerCount})` },
                  { id: 'sales', label: `${t.auditLog.filterSales} (${sales.length})` },
                  {
                    id: 'stock-in',
                    label: `${t.auditLog.filterStockIn} (${stockIns.length})`,
                  },
                  {
                    id: 'audits',
                    label: `${t.auditLog.filterAudits} (${audits.length})`,
                  },
                ] as const
              ).map((tab) => {
                const isActive = ledgerFilter === tab.id;
                return (
                  <button
                    key={tab.id}
                    type="button"
                    aria-pressed={isActive}
                    onClick={() => setLedgerFilter(tab.id)}
                    className={`min-h-[34px] px-3 py-1.5 text-xs font-medium rounded transition-colors ${
                      isActive
                        ? 'bg-[#FFFFFF] text-[#14171A] font-semibold'
                        : 'text-[#4A5056] hover:text-[#14171A]'
                    }`}
                  >
                    {tab.label}
                  </button>
                );
              })}
            </div>

            <div className="relative sm:w-72">
              <Search className="w-4 h-4 text-[#6E757C] absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="search"
                value={ledgerSearch}
                onChange={(e) => setLedgerSearch(e.target.value)}
                placeholder={t.auditLog.searchPlaceholder}
                className="w-full min-h-[38px] pl-9 pr-3 py-1.5 text-xs bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
              />
            </div>
          </section>

          {/* Chronological Ledger Entries */}
          <section className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden">
            {unifiedLedger.length === 0 ? (
              <div className="p-8 text-center space-y-2">
                <h3 className="text-base font-semibold text-[#14171A]">
                  {t.auditLog.emptyLedgerTitle}
                </h3>
                <p className="text-xs text-[#4A5056] max-w-md mx-auto">
                  {t.auditLog.emptyLedgerDescription}
                </p>
              </div>
            ) : (
              <div className="divide-y divide-[#ECEAE3]">
                {unifiedLedger.map((entry) => {
                  if (entry.kind === 'sale' && entry.sale) {
                    const sale = entry.sale;
                    return (
                      <div key={sale.id} className="p-4 sm:px-5 space-y-2.5">
                        <div className="flex flex-wrap items-baseline justify-between gap-2">
                          <div className="flex items-baseline gap-2">
                            <span className="text-xs font-bold uppercase tracking-wider text-[#B84A14]">
                              {t.auditLog.saleBadgeLabel}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-xs font-mono-tabular text-[#6E757C]">
                              {sale.id}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-xs text-[#4A5056]">
                              {sale.customerNote || t.auditLog.saleNoteFallback}
                            </span>
                          </div>
                          <span className="text-xs font-mono-tabular text-[#6E757C]">
                            {new Date(sale.createdAt).toLocaleString()}
                          </span>
                        </div>

                        <div className="divide-y divide-[#ECEAE3] bg-[#F6F5F1] border border-[#DCD9D0] rounded p-2.5 space-y-1.5">
                          {sale.items.map((line) => (
                            <div
                              key={`${sale.id}-${line.materialId}`}
                              className="pt-1.5 first:pt-0 flex flex-wrap items-center justify-between gap-2 text-xs font-mono-tabular"
                            >
                              <span className="font-sans font-semibold text-[#14171A]">
                                {line.materialName}
                              </span>
                              <span className="text-[#4A5056]">
                                {formatQuantity(line.quantity)}{' '}
                                {t.units[line.unit]} ×{' '}
                                {formatETB(line.unitSellingPrice)} ={' '}
                                <strong className="text-[#14171A]">
                                  {formatETB(line.lineTotal)}
                                </strong>
                              </span>
                            </div>
                          ))}
                        </div>

                        <div className="flex items-center justify-end gap-5 text-xs font-mono-tabular">
                          <span>
                            {t.pos.totalRevenueLabel}:{' '}
                            <strong className="text-[#14171A]">
                              {formatETB(sale.totalRevenue)}
                            </strong>
                          </span>
                          <span className="text-[#166534]">
                            {t.pos.estimatedProfitLabel}:{' '}
                            <strong>{formatETB(sale.totalProfit)}</strong>
                          </span>
                        </div>
                      </div>
                    );
                  }

                  if (entry.kind === 'stock-in' && entry.stockIn) {
                    const st = entry.stockIn;
                    return (
                      <div key={st.id} className="p-4 sm:px-5 space-y-2">
                        <div className="flex flex-wrap items-baseline justify-between gap-2">
                          <div className="flex items-baseline gap-2">
                            <span className="text-xs font-bold uppercase tracking-wider text-[#166534]">
                              {t.auditLog.stockInBadgeLabel}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-sm font-semibold text-[#14171A]">
                              {st.materialName}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-xs text-[#4A5056]">
                              {st.supplierNote || t.stockIn.supplierNoteFallback}
                            </span>
                          </div>
                          <span className="text-xs font-mono-tabular text-[#6E757C]">
                            {new Date(st.createdAt).toLocaleString()}
                          </span>
                        </div>

                        <div className="flex flex-wrap items-center justify-between gap-3 text-xs font-mono-tabular bg-[#F6F5F1] border border-[#DCD9D0] rounded p-2.5">
                          <span className="font-bold text-[#166534]">
                            +{formatQuantity(st.quantityAdded)} {t.units[st.unit]}
                          </span>
                          <span>
                            {t.stockIn.unitCostCol}:{' '}
                            <strong>{formatETB(st.unitPurchaseCost)}</strong>
                          </span>
                          <span>
                            {t.stockIn.totalCostCol}:{' '}
                            <strong>{formatETB(st.totalCost)}</strong>
                          </span>
                          <span>
                            {t.stockIn.stockTransitionCol}:{' '}
                            <strong>
                              {formatQuantity(st.previousStock)} →{' '}
                              {formatQuantity(st.newStock)} {t.units[st.unit]}
                            </strong>
                          </span>
                        </div>
                      </div>
                    );
                  }

                  if (entry.kind === 'audit' && entry.audit) {
                    const audit = entry.audit;
                    return (
                      <div key={audit.id} className="p-4 sm:px-5 space-y-2.5">
                        <div className="flex flex-wrap items-baseline justify-between gap-2">
                          <div className="flex items-baseline gap-2">
                            <span className="text-xs font-bold uppercase tracking-wider text-[#9A3412]">
                              {t.auditLog.auditBadgeLabel}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-xs font-mono-tabular text-[#6E757C]">
                              {audit.id}
                            </span>
                            <span aria-hidden="true" className="text-[#6E757C]">
                              ·
                            </span>
                            <span className="text-xs text-[#4A5056]">
                              {audit.note || t.auditLog.auditNoteFallback}
                            </span>
                          </div>
                          <span className="text-xs font-mono-tabular text-[#6E757C]">
                            {new Date(audit.createdAt).toLocaleString()}
                          </span>
                        </div>

                        <div className="divide-y divide-[#ECEAE3] bg-[#F6F5F1] border border-[#DCD9D0] rounded p-2.5 space-y-1.5">
                          {audit.adjustments.map((adj) => (
                            <div
                              key={`${audit.id}-${adj.materialId}`}
                              className="pt-1.5 first:pt-0 flex flex-wrap items-center justify-between gap-2 text-xs font-mono-tabular"
                            >
                              <span className="font-sans font-semibold text-[#14171A]">
                                {adj.materialName}
                              </span>
                              <div className="flex items-center gap-3">
                                <span className="text-[#4A5056] inline-flex items-center gap-1">
                                  <span>{formatQuantity(adj.expectedStock)}</span>
                                  <ArrowRight className="w-3 h-3 text-[#6E757C]" />
                                  <strong className="text-[#14171A]">
                                    {formatQuantity(adj.physicalCount)}{' '}
                                    {t.units[adj.unit]}
                                  </strong>
                                </span>
                                <span
                                  className={`font-bold ${
                                    adj.variance === 0
                                      ? 'text-[#166534]'
                                      : adj.variance > 0
                                        ? 'text-[#9A3412]'
                                        : 'text-[#B91C1C]'
                                  }`}
                                >
                                  (
                                  {adj.variance > 0
                                    ? `+${formatQuantity(adj.variance)}`
                                    : formatQuantity(adj.variance)}{' '}
                                  {t.units[adj.unit]})
                                </span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    );
                  }

                  return null;
                })}
              </div>
            )}
          </section>
        </div>
      )}
    </div>
  );
};
