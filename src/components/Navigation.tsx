import React from 'react';
import {
  ArrowDownToLine,
  ClipboardCheck,
  LayoutDashboard,
  Package,
  ShoppingCart,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { AppRouteTab } from '../types/erp';

interface NavItemConfig {
  id: AppRouteTab;
  icon: React.FC<{ className?: string }>;
}

const NAV_ITEMS: NavItemConfig[] = [
  { id: 'dashboard', icon: LayoutDashboard },
  { id: 'materials', icon: Package },
  { id: 'pos', icon: ShoppingCart },
  { id: 'stock-in', icon: ArrowDownToLine },
  { id: 'audit-log', icon: ClipboardCheck },
];

/**
 * Desktop Left Navigation Rail (>= 1024px) per docs/UI_UX_SPEC.md Section 3.4 & 5.
 */
export const DesktopNavigationRail: React.FC = () => {
  const { activeTab, setActiveTab, t, state } = useErpStore();

  return (
    <aside
      aria-label="Primary Store Navigation"
      className="hidden lg:flex lg:flex-col lg:w-60 lg:shrink-0 border-r border-[#DCD9D0] bg-[#FFFFFF] min-h-[calc(100vh-3.5rem)] justify-between p-4"
    >
      <nav className="space-y-1">
        {NAV_ITEMS.map(({ id, icon: Icon }) => {
          const isActive = activeTab === id;
          return (
            <button
              key={id}
              type="button"
              onClick={() => setActiveTab(id)}
              aria-current={isActive ? 'page' : undefined}
              className={`w-full min-h-[44px] px-3.5 py-2.5 rounded-md text-sm font-medium flex items-center justify-between transition-colors ${
                isActive
                  ? 'bg-[#B84A14] text-[#FFFFFF]'
                  : 'text-[#14171A] hover:bg-[#F6F5F1]'
              }`}
            >
              <span className="flex items-center gap-3">
                <Icon className="w-4 h-4 shrink-0" />
                <span>{t.nav[id]}</span>
              </span>
              {id === 'materials' && (
                <span
                  className={`font-mono-tabular text-xs ${
                    isActive ? 'text-[#FFFFFF]/90' : 'text-[#6E757C]'
                  }`}
                >
                  {state.materials.length}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      <div className="pt-4 border-t border-[#ECEAE3] text-xs text-[#4A5056] space-y-1">
        <p className="font-semibold text-[#14171A]">{t.appSubtitle}</p>
        <p className="font-mono-tabular text-[#6E757C]">
          {t.currencyLabel} · {state.materials.length} {t.kpis.registeredMaterials}
        </p>
      </div>
    </aside>
  );
};

/**
 * Mobile & Tablet 5-Tab Bottom Navigation Bar (< 1024px) per docs/UI_UX_SPEC.md Section 3.4 & 5.
 */
export const MobileBottomNavigation: React.FC = () => {
  const { activeTab, setActiveTab, t } = useErpStore();

  return (
    <nav
      aria-label="Mobile Store Navigation"
      className="lg:hidden fixed bottom-0 inset-x-0 z-30 h-16 bg-[#FFFFFF] border-t border-[#DCD9D0] grid grid-cols-5 px-1"
    >
      {NAV_ITEMS.map(({ id, icon: Icon }) => {
        const isActive = activeTab === id;
        return (
          <button
            key={id}
            type="button"
            onClick={() => setActiveTab(id)}
            aria-current={isActive ? 'page' : undefined}
            className={`min-h-[44px] flex flex-col items-center justify-center gap-1 px-1 transition-colors ${
              isActive
                ? 'text-[#B84A14] font-semibold'
                : 'text-[#4A5056] hover:text-[#14171A]'
            }`}
          >
            <Icon className="w-4 h-4 shrink-0" />
            <span className="text-[11px] leading-tight truncate max-w-full">
              {t.nav[id]}
            </span>
          </button>
        );
      })}
    </nav>
  );
};
