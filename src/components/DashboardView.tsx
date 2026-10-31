import React, { useMemo } from 'react';
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowRight,
  CheckCircle2,
  ClipboardCheck,
  Package,
  ShoppingCart,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { round2 } from '../domain/inventoryEngine';
import { formatETB, formatQuantity } from '../i18n/translations';
import { ALLOWED_CATEGORIES, MaterialCategory } from '../types/erp';

interface RecentActivityEntry {
  id: string;
  kind: 'sale' | 'stock-in' | 'audit';
  createdAt: string;
  title: string;
  subtitle: string;
  rightPrimary: string;
  rightSecondary: string;
}

export const DashboardView: React.FC = () => {
  const {
    state,
    t,
    isLoading,
    setActiveTab,
    addToPosCart,
    openStockInForMaterial,
  } = useErpStore();

  const { summary, materials, sales, stockIns, audits } = state;

  // Low-Stock & Out-of-Stock Materials (FR-020: currentStock <= minStockLevel)
  const lowStockMaterials = useMemo(
    () => materials.filter((m) => m.currentStock <= m.minStockLevel),
    [materials]
  );

  // Inventory Valuation by Category Breakdown
  const categoryBreakdown = useMemo(() => {
    return ALLOWED_CATEGORIES.map((category: MaterialCategory) => {
      const items = materials.filter((m) => m.category === category);
      const costValue = round2(
        items.reduce((sum, m) => sum + m.currentStock * m.unitCost, 0)
      );
      const retailValue = round2(
        items.reduce(
          (sum, m) => sum + m.currentStock * m.defaultSellingPrice,
          0
        )
      );
      return {
        category,
        count: items.length,
        costValue,
        retailValue,
      };
    }).filter((entry) => entry.count > 0);
  }, [materials]);

  // Recent 5 Store Transactions across Sales, Stock-Ins, and Audits (SCR-01)
  const recentActivities = useMemo<RecentActivityEntry[]>(() => {
    const entries: RecentActivityEntry[] = [];

    for (const s of sales) {
      entries.push({
        id: s.id,
        kind: 'sale',
        createdAt: s.createdAt,
        title: `${t.auditLog.saleBadgeLabel} · ${s.items.map((i) => i.materialName).join(', ')}`,
        subtitle: s.customerNote || t.auditLog.saleNoteFallback,
        rightPrimary: formatETB(s.totalRevenue),
        rightSecondary: `${t.pos.estimatedProfitLabel}: ${formatETB(s.totalProfit)}`,
      });
    }

    for (const st of stockIns) {
      entries.push({
        id: st.id,
        kind: 'stock-in',
        createdAt: st.createdAt,
        title: `${t.auditLog.stockInBadgeLabel} · ${st.materialName}`,
        subtitle: st.supplierNote || t.stockIn.supplierNoteFallback,
        rightPrimary: `+${formatQuantity(st.quantityAdded)} ${t.units[st.unit]}`,
        rightSecondary: formatETB(st.totalCost),
      });
    }

    for (const a of audits) {
      entries.push({
        id: a.id,
        kind: 'audit',
        createdAt: a.createdAt,
        title: `${t.auditLog.auditBadgeLabel} (${a.adjustments.length})`,
        subtitle: a.note || t.auditLog.auditNoteFallback,
        rightPrimary: a.adjustments
          .map(
            (adj) =>
              `${adj.variance > 0 ? `+${formatQuantity(adj.variance)}` : formatQuantity(adj.variance)} ${t.units[adj.unit]}`
          )
          .join(', '),
        rightSecondary: new Date(a.createdAt).toLocaleTimeString([], {
          hour: '2-digit',
          minute: '2-digit',
        }),
      });
    }

    return entries
      .sort(
        (a, b) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      )
      .slice(0, 5);
  }, [sales, stockIns, audits, t]);

  return (
    <div className="space-y-6">
      {/* Top Route Header & Quick Operation Bar (SCR-01) */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 border-b border-[#DCD9D0] pb-4">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#14171A]">
            {t.nav.dashboard} — {t.shell.architectureInitialized}
          </h2>
          <p className="text-sm text-[#4A5056] mt-0.5">
            {t.shell.moduleReadyDescription}
          </p>
        </div>

        {/* Quick Operation Bar */}
        <div className="flex flex-wrap items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => setActiveTab('pos')}
            className="min-h-[42px] px-3.5 py-2 text-xs font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center gap-1.5"
          >
            <ShoppingCart className="w-3.5 h-3.5" />
            <span>{t.shell.openPos}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('stock-in')}
            className="min-h-[42px] px-3.5 py-2 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors flex items-center gap-1.5"
          >
            <ArrowDownToLine className="w-3.5 h-3.5 text-[#B84A14]" />
            <span>{t.shell.openStockIn}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('audit-log')}
            className="min-h-[42px] px-3.5 py-2 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors flex items-center gap-1.5"
          >
            <ClipboardCheck className="w-3.5 h-3.5 text-[#4A5056]" />
            <span>{t.shell.openAudit}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('materials')}
            className="min-h-[42px] px-3.5 py-2 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors flex items-center gap-1.5"
          >
            <Package className="w-3.5 h-3.5 text-[#4A5056]" />
            <span>{t.shell.openMaterials}</span>
          </button>
        </div>
      </div>

      {/* 4-Column KPI Summary Grid (FR-020) */}
      <section
        aria-label="Store KPI Summary"
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4">
          <p className="text-xs font-medium text-[#4A5056]">
            {t.kpis.totalRevenue}
          </p>
          <p className="mt-1.5 text-xl font-bold font-mono-tabular text-[#14171A]">
            {formatETB(summary.totalRevenue)}
          </p>
          <p className="mt-1 text-xs text-[#6E757C] font-mono-tabular">
            {t.kpis.completedSales}: {sales.length}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4">
          <p className="text-xs font-medium text-[#4A5056]">
            {t.kpis.totalProfit}
          </p>
          <p className="mt-1.5 text-xl font-bold font-mono-tabular text-[#166534]">
            {formatETB(summary.totalProfit)}
          </p>
          <p className="mt-1 text-xs text-[#6E757C]">
            {t.currencyLabel} · {t.shell.syncStatusConnected}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4">
          <p className="text-xs font-medium text-[#4A5056]">
            {t.kpis.inventoryCostValue}
          </p>
          <p className="mt-1.5 text-xl font-bold font-mono-tabular text-[#14171A]">
            {formatETB(summary.inventoryCostValue)}
          </p>
          <p className="mt-1 text-xs text-[#6E757C] font-mono-tabular">
            {t.kpis.inventoryRetailValue}:{' '}
            {formatETB(summary.inventoryRetailValue)}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg p-4">
          <p className="text-xs font-medium text-[#4A5056]">
            {t.kpis.lowStockAlerts}
          </p>
          <p
            className={`mt-1.5 text-xl font-bold font-mono-tabular ${
              summary.lowStockCount > 0 ? 'text-[#9A3412]' : 'text-[#166534]'
            }`}
          >
            {summary.lowStockCount}
          </p>
          <p className="mt-1 text-xs text-[#6E757C] font-mono-tabular">
            {t.kpis.registeredMaterials}: {materials.length} ·{' '}
            {t.kpis.groundAudits}: {audits.length}
          </p>
        </div>
      </section>

      {/* Main 2-Column Split (SCR-01: Left 7 cols Low-Stock & Active Catalog, Right 5 cols Category Valuation & Recent Activity) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column (7 cols) */}
        <div className="lg:col-span-7 space-y-6">
          {/* 1. Low-Stock & Restock Attention List (FR-020) */}
          <section
            aria-label={t.dashboard.lowStockHeading}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
          >
            <div className="px-4 sm:px-5 py-3.5 border-b border-[#ECEAE3] flex items-center justify-between gap-2">
              <div>
                <h3 className="text-base font-semibold text-[#14171A] flex items-center gap-2">
                  <AlertTriangle
                    className={`w-4 h-4 ${
                      lowStockMaterials.length > 0
                        ? 'text-[#9A3412]'
                        : 'text-[#166534]'
                    }`}
                  />
                  <span>
                    {t.dashboard.lowStockHeading} ({lowStockMaterials.length})
                  </span>
                </h3>
                <p className="text-xs text-[#4A5056] mt-0.5">
                  {t.dashboard.lowStockSubtitle}
                </p>
              </div>
            </div>

            {lowStockMaterials.length === 0 ? (
              <div className="p-5 flex items-start gap-3 bg-[#F0FDF4]/60">
                <CheckCircle2 className="w-5 h-5 text-[#166534] shrink-0 mt-0.5" />
                <div>
                  <h4 className="text-sm font-semibold text-[#166534]">
                    {t.dashboard.allStockHealthyTitle}
                  </h4>
                  <p className="text-xs text-[#4A5056] mt-0.5">
                    {t.dashboard.allStockHealthyDescription}
                  </p>
                </div>
              </div>
            ) : (
              <div className="divide-y divide-[#ECEAE3]">
                {lowStockMaterials.map((item) => (
                  <div
                    key={item.id}
                    className="p-4 sm:px-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-[#FFF7ED]/40 hover:bg-[#FFF7ED] transition-colors"
                  >
                    <div className="min-w-0">
                      <div className="flex items-baseline gap-2">
                        <h4 className="text-sm font-semibold text-[#14171A]">
                          {item.name}
                        </h4>
                        <span aria-hidden="true" className="text-[#6E757C]">
                          ·
                        </span>
                        <span className="text-xs font-semibold text-[#9A3412]">
                          {t.shell.lowStockFlag}
                        </span>
                      </div>
                      <p className="text-xs text-[#4A5056] mt-0.5 font-mono-tabular">
                        {t.shell.stockCol}:{' '}
                        <strong className="text-[#9A3412]">
                          {formatQuantity(item.currentStock)}{' '}
                          {t.units[item.unit]}
                        </strong>{' '}
                        · {t.shell.minStockCol}:{' '}
                        {formatQuantity(item.minStockLevel)}{' '}
                        {t.units[item.unit]} · {t.shell.costCol}:{' '}
                        {formatETB(item.unitCost)}
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={() => openStockInForMaterial(item.id)}
                      aria-label={`${t.dashboard.restockNowBtn} ${item.name}`}
                      className="min-h-[38px] px-3 py-1.5 text-xs font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center gap-1.5 shrink-0 self-start sm:self-auto"
                    >
                      <ArrowDownToLine className="w-3.5 h-3.5" />
                      <span>{t.dashboard.restockNowBtn}</span>
                    </button>
                  </div>
                ))}
              </div>
            )}
          </section>

          {/* 2. Active Ground-Stock Directory */}
          <section
            aria-label={t.dashboard.activeDirectoryHeading}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
          >
            <div className="px-4 sm:px-5 py-3.5 border-b border-[#ECEAE3] flex items-center justify-between gap-2">
              <div>
                <h3 className="text-base font-semibold text-[#14171A]">
                  {t.dashboard.activeDirectoryHeading} ({materials.length})
                </h3>
                <p className="text-xs text-[#4A5056] mt-0.5">
                  {t.dashboard.activeDirectorySubtitle}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveTab('materials')}
                className="text-xs font-semibold text-[#B84A14] hover:underline flex items-center gap-1"
              >
                <span>{t.shell.openMaterials}</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {isLoading ? (
              <div className="p-6 text-sm text-[#4A5056]">
                {t.shell.loadingState}
              </div>
            ) : (
              <div className="divide-y divide-[#ECEAE3]">
                {materials.map((item) => {
                  const isLowStock = item.currentStock <= item.minStockLevel;
                  return (
                    <div
                      key={item.id}
                      className="px-4 sm:px-5 py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-[#F6F5F1]/60 transition-colors"
                    >
                      <div className="min-w-0">
                        <div className="flex items-baseline gap-2">
                          <h4 className="text-sm font-semibold text-[#14171A]">
                            {item.name}
                          </h4>
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
                        <p className="text-xs text-[#4A5056] mt-0.5">
                          {t.categories[item.category]} · {item.specs}
                        </p>
                      </div>

                      <div className="flex items-center justify-between sm:justify-end gap-4 shrink-0 font-mono-tabular">
                        <div className="text-right">
                          <p className="text-[11px] text-[#6E757C]">
                            {t.shell.priceCol}
                          </p>
                          <p className="text-xs font-semibold text-[#14171A]">
                            {formatETB(item.defaultSellingPrice)}
                          </p>
                        </div>

                        <div className="min-w-[88px] text-right">
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

                        <button
                          type="button"
                          disabled={item.currentStock <= 0}
                          onClick={() => {
                            addToPosCart(item.id);
                            setActiveTab('pos');
                          }}
                          aria-label={`${t.dashboard.sellQuickBtn} ${item.name}`}
                          className="min-h-[36px] px-2.5 py-1 text-xs font-sans font-medium rounded border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] flex items-center gap-1 disabled:opacity-45"
                        >
                          <ShoppingCart className="w-3.5 h-3.5 text-[#B84A14]" />
                          <span>{t.dashboard.sellQuickBtn}</span>
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </section>
        </div>

        {/* Right Column (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          {/* 1. Inventory Valuation by Category Breakdown */}
          <section
            aria-label={t.dashboard.categoryBreakdownHeading}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
          >
            <div className="px-4 sm:px-5 py-3.5 border-b border-[#ECEAE3]">
              <h3 className="text-base font-semibold text-[#14171A]">
                {t.dashboard.categoryBreakdownHeading}
              </h3>
              <p className="text-xs text-[#4A5056] mt-0.5">
                {t.dashboard.categoryBreakdownSubtitle}
              </p>
            </div>

            <div className="divide-y divide-[#ECEAE3]">
              {categoryBreakdown.map((cat) => (
                <div
                  key={cat.category}
                  className="px-4 sm:px-5 py-3 flex items-center justify-between gap-3"
                >
                  <div>
                    <h4 className="text-sm font-semibold text-[#14171A]">
                      {t.categories[cat.category]}
                    </h4>
                    <p className="text-xs text-[#6E757C] font-mono-tabular">
                      {cat.count} {t.dashboard.itemsCountLabel}
                    </p>
                  </div>

                  <div className="text-right font-mono-tabular">
                    <p className="text-xs font-bold text-[#14171A]">
                      {formatETB(cat.costValue)}
                    </p>
                    <p className="text-[11px] text-[#6E757C]">
                      {t.kpis.inventoryRetailValue}:{' '}
                      {formatETB(cat.retailValue)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* 2. Recent Store Activity Feed (Latest 5 Transactions) */}
          <section
            aria-label={t.dashboard.recentActivityHeading}
            className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden"
          >
            <div className="px-4 sm:px-5 py-3.5 border-b border-[#ECEAE3] flex items-center justify-between gap-2">
              <div>
                <h3 className="text-base font-semibold text-[#14171A]">
                  {t.dashboard.recentActivityHeading}
                </h3>
                <p className="text-xs text-[#4A5056] mt-0.5">
                  {t.dashboard.recentActivitySubtitle}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveTab('audit-log')}
                className="text-xs font-semibold text-[#B84A14] hover:underline flex items-center gap-1 shrink-0"
              >
                <span>{t.dashboard.viewFullLedgerBtn}</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {recentActivities.length === 0 ? (
              <div className="p-6 text-center space-y-1.5">
                <h4 className="text-sm font-semibold text-[#14171A]">
                  {t.dashboard.noActivityYetTitle}
                </h4>
                <p className="text-xs text-[#4A5056]">
                  {t.dashboard.noActivityYetDescription}
                </p>
              </div>
            ) : (
              <div className="divide-y divide-[#ECEAE3]">
                {recentActivities.map((act) => (
                  <div
                    key={act.id}
                    className="px-4 sm:px-5 py-3 flex items-center justify-between gap-3"
                  >
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-[#14171A] truncate">
                        {act.title}
                      </p>
                      <p className="text-[11px] text-[#6E757C] truncate">
                        {act.subtitle}
                      </p>
                    </div>
                    <div className="text-right font-mono-tabular shrink-0">
                      <p className="text-xs font-bold text-[#14171A]">
                        {act.rightPrimary}
                      </p>
                      <p className="text-[11px] text-[#6E757C]">
                        {act.rightSecondary}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
};
