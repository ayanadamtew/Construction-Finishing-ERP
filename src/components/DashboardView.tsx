import React, { useMemo } from 'react';
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowRight,
  CheckCircle2,
  Package,
  Receipt,
  ShoppingCart,
  TrendingUp,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import {
  formatETB,
  formatQuantity,
  getCategoryLabel,
} from '../i18n/translations';

export const DashboardView: React.FC = () => {
  const {
    state,
    t,
    setActiveTab,
    openStockInForMaterial,
  } = useErpStore();

  const { summary, materials, sales, categories } = state;

  const activeMaterials = useMemo(
    () => materials.filter((m) => !m.isArchived),
    [materials]
  );

  // Low-Stock & Out-of-Stock Materials (FR-020: currentStock <= minStockLevel)
  const lowStockMaterials = useMemo(
    () => activeMaterials.filter((m) => m.currentStock <= m.minStockLevel),
    [activeMaterials]
  );

  const activeSales = useMemo(
    () => sales.filter((s) => !s.isReversed),
    [sales]
  );

  const recentSales = useMemo(() => activeSales.slice(0, 4), [activeSales]);
  const displayedLowStock = useMemo(
    () => lowStockMaterials.slice(0, 4),
    [lowStockMaterials]
  );

  return (
    <div className="space-y-5">
      {/* 1. Compact 2x2 / 4-Column Summary Indicators */}
      <section
        aria-label="Store KPI Summary"
        className="grid grid-cols-2 lg:grid-cols-4 gap-3"
      >
        <div className="bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl p-3.5">
          <div className="flex items-center gap-2 text-xs font-semibold text-[#475569]">
            <span className="p-1.5 rounded-lg bg-[#FEF3C7] text-[#D97706]">
              <Receipt className="w-3.5 h-3.5" />
            </span>
            <span className="truncate">{t.kpis.completedSales}</span>
          </div>
          <p className="mt-2 text-lg sm:text-xl font-extrabold font-mono-tabular text-[#0F172A] truncate">
            {activeSales.length}
          </p>
          <p className="mt-0.5 text-[11px] text-[#64748B] truncate">
            {t.kpis.totalProfit}: {formatETB(summary.totalProfit)}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl p-3.5">
          <div className="flex items-center gap-2 text-xs font-semibold text-[#475569]">
            <span className="p-1.5 rounded-lg bg-[#DCFCE7] text-[#16A34A]">
              <TrendingUp className="w-3.5 h-3.5" />
            </span>
            <span className="truncate">{t.kpis.totalRevenue}</span>
          </div>
          <p className="mt-2 text-lg sm:text-xl font-extrabold font-mono-tabular text-[#0F172A] truncate">
            {formatETB(summary.totalRevenue)}
          </p>
          <p className="mt-0.5 text-[11px] text-[#16A34A] font-semibold truncate">
            +{formatETB(summary.totalProfit)}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl p-3.5">
          <div className="flex items-center gap-2 text-xs font-semibold text-[#475569]">
            <span className="p-1.5 rounded-lg bg-[#F1F5F9] text-[#0F172A]">
              <Package className="w-3.5 h-3.5" />
            </span>
            <span className="truncate">{t.kpis.registeredMaterials}</span>
          </div>
          <p className="mt-2 text-lg sm:text-xl font-extrabold font-mono-tabular text-[#0F172A] truncate">
            {activeMaterials.length}
          </p>
          <p className="mt-0.5 text-[11px] text-[#64748B] font-mono-tabular truncate">
            {formatETB(summary.inventoryCostValue)}
          </p>
        </div>

        <div className="bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl p-3.5">
          <div className="flex items-center gap-2 text-xs font-semibold text-[#475569]">
            <span
              className={`p-1.5 rounded-lg ${
                summary.lowStockCount > 0
                  ? 'bg-[#FEF3C7] text-[#D97706]'
                  : 'bg-[#DCFCE7] text-[#16A34A]'
              }`}
            >
              <AlertTriangle className="w-3.5 h-3.5" />
            </span>
            <span className="truncate">{t.kpis.lowStockAlerts}</span>
          </div>
          <p
            className={`mt-2 text-lg sm:text-xl font-extrabold font-mono-tabular truncate ${
              summary.lowStockCount > 0 ? 'text-[#D97706]' : 'text-[#16A34A]'
            }`}
          >
            {summary.lowStockCount}
          </p>
          <p className="mt-0.5 text-[11px] text-[#64748B] truncate">
            {summary.lowStockCount > 0
              ? t.shell.lowStockFlag
              : t.shell.inStockFlag}
          </p>
        </div>
      </section>

      {/* 2. Streamlined Primary Operational Actions */}
      <div className="grid grid-cols-2 gap-3">
        <button
          type="button"
          onClick={() => setActiveTab('pos')}
          className="min-h-[46px] px-4 py-2.5 text-xs sm:text-sm font-semibold rounded-xl bg-[#D97706] text-[#FFFFFF] hover:bg-[#B45309] transition-colors flex items-center justify-center gap-2"
        >
          <ShoppingCart className="w-4 h-4 shrink-0" />
          <span className="truncate">{t.shell.openPos}</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('stock-in')}
          className="min-h-[46px] px-4 py-2.5 text-xs sm:text-sm font-semibold rounded-xl border border-[#E2E8F0] bg-[#FFFFFF] text-[#0F172A] hover:bg-[#F8FAFC] transition-colors flex items-center justify-center gap-2"
        >
          <ArrowDownToLine className="w-4 h-4 text-[#D97706] shrink-0" />
          <span className="truncate">{t.shell.openStockIn}</span>
        </button>
      </div>

      {/* 3. Main 2-Column Split: Low-Stock Materials & Recent Sales */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        {/* Left: Low-Stock Materials (Limited + View All) */}
        <section
          aria-label={t.dashboard.lowStockHeading}
          className="lg:col-span-6 bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl overflow-hidden"
        >
          <div className="px-4 py-3 border-b border-[#E2E8F0] flex items-center justify-between gap-2">
            <div className="flex items-center gap-2 min-w-0">
              <h3 className="text-sm font-bold text-[#0F172A] truncate">
                {t.dashboard.lowStockHeading}
              </h3>
              <span
                className={`text-xs font-bold px-2 py-0.5 rounded-full ${
                  lowStockMaterials.length > 0
                    ? 'bg-[#FEF3C7] text-[#B45309]'
                    : 'bg-[#DCFCE7] text-[#16A34A]'
                }`}
              >
                {lowStockMaterials.length}
              </span>
            </div>
            <button
              type="button"
              onClick={() => setActiveTab('materials')}
              className="text-xs font-semibold text-[#D97706] hover:underline flex items-center gap-1 shrink-0"
            >
              <span>View All</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {lowStockMaterials.length === 0 ? (
            <div className="p-5 flex items-center gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#16A34A] shrink-0" />
              <div>
                <h4 className="text-xs font-semibold text-[#0F172A]">
                  {t.dashboard.allStockHealthyTitle}
                </h4>
                <p className="text-xs text-[#64748B]">
                  {t.dashboard.allStockHealthyDescription}
                </p>
              </div>
            </div>
          ) : (
            <div className="divide-y divide-[#E2E8F0]">
              {displayedLowStock.map((item) => (
                <div
                  key={item.id}
                  className="px-4 py-3 flex items-center justify-between gap-3 hover:bg-[#F8FAFC] transition-colors"
                >
                  <div className="min-w-0 flex-1">
                    <h4 className="text-sm font-semibold text-[#0F172A] truncate">
                      {item.name}
                    </h4>
                    <p className="text-xs text-[#64748B] truncate mt-0.5">
                      <span className="font-mono-tabular font-bold text-[#D97706]">
                        {formatQuantity(item.currentStock)} {t.units[item.unit]}
                      </span>
                      {' · '}
                      <span className="font-mono-tabular">
                        {t.shell.minStockCol}: {formatQuantity(item.minStockLevel)}
                      </span>
                      {' · '}
                      {getCategoryLabel(t, item.category, categories)}
                    </p>
                  </div>

                  <button
                    type="button"
                    onClick={() => openStockInForMaterial(item.id)}
                    aria-label={`${t.dashboard.restockNowBtn} ${item.name}`}
                    className="min-h-[34px] px-3 py-1.5 text-xs font-semibold rounded-lg bg-[#FEF3C7] text-[#B45309] hover:bg-[#D97706] hover:text-white transition-colors shrink-0"
                  >
                    {t.dashboard.restockNowBtn}
                  </button>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* Right: Recent Sales (Clean Transaction List + View All) */}
        <section
          aria-label={t.dashboard.recentActivityHeading}
          className="lg:col-span-6 bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl overflow-hidden"
        >
          <div className="px-4 py-3 border-b border-[#E2E8F0] flex items-center justify-between gap-2">
            <div className="flex items-center gap-2 min-w-0">
              <h3 className="text-sm font-bold text-[#0F172A] truncate">
                {t.dashboard.recentActivityHeading}
              </h3>
              <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-[#F1F5F9] text-[#475569]">
                {activeSales.length}
              </span>
            </div>
            <button
              type="button"
              onClick={() => setActiveTab('audit-log')}
              className="text-xs font-semibold text-[#D97706] hover:underline flex items-center gap-1 shrink-0"
            >
              <span>{t.dashboard.viewFullLedgerBtn}</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {recentSales.length === 0 ? (
            <div className="p-6 text-center space-y-1">
              <h4 className="text-xs font-semibold text-[#0F172A]">
                {t.dashboard.noActivityYetTitle}
              </h4>
              <p className="text-xs text-[#64748B]">
                {t.dashboard.noActivityYetDescription}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-[#E2E8F0]">
              {recentSales.map((sale) => {
                const dateStr = sale.createdAt.split('T')[0];
                return (
                  <div
                    key={sale.id}
                    className="px-4 py-3 flex items-center justify-between gap-3 hover:bg-[#F8FAFC] transition-colors"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-[#0F172A] truncate">
                        {sale.customerNote || sale.id}
                      </p>
                      <p className="text-xs text-[#64748B] truncate mt-0.5">
                        {sale.id} · {dateStr} · {sale.items.length} item(s)
                      </p>
                    </div>
                    <div className="text-right font-mono-tabular shrink-0">
                      <p className="text-sm font-bold text-[#0F172A]">
                        {formatETB(sale.totalRevenue)}
                      </p>
                      <p className="text-[11px] font-semibold text-[#16A34A]">
                        +{formatETB(sale.totalProfit)}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      </div>
    </div>
  );
};
