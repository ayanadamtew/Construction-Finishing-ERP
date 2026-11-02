import React from 'react';
import {
  ArrowDownToLine,
  LayoutDashboard,
  MoreHorizontal,
  Package,
  ShoppingCart,
} from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { AppRouteTab } from '../types/erp';

interface NavItemConfig {
  id: AppRouteTab;
  shortLabelKey: 'dashboard' | 'materials' | 'pos' | 'stock-in' | 'audit-log';
  shortLabelFallback: string;
  icon: React.FC<{ className?: string }>;
}

const NAV_ITEMS: NavItemConfig[] = [
  {
    id: 'dashboard',
    shortLabelKey: 'dashboard',
    shortLabelFallback: 'Dashboard',
    icon: LayoutDashboard,
  },
  {
    id: 'materials',
    shortLabelKey: 'materials',
    shortLabelFallback: 'Materials',
    icon: Package,
  },
  {
    id: 'pos',
    shortLabelKey: 'pos',
    shortLabelFallback: 'Sales',
    icon: ShoppingCart,
  },
  {
    id: 'stock-in',
    shortLabelKey: 'stock-in',
    shortLabelFallback: 'Inventory',
    icon: ArrowDownToLine,
  },
  {
    id: 'audit-log',
    shortLabelKey: 'audit-log',
    shortLabelFallback: 'More',
    icon: MoreHorizontal,
  },
];

/**
 * Desktop Left Navigation Rail (>= 1024px)
 */
export const DesktopNavigationRail: React.FC = () => {
  const { activeTab, setActiveTab, t, state } = useErpStore();

  return (
    <aside
      aria-label="Primary Store Navigation"
      className="hidden lg:flex lg:flex-col lg:w-60 lg:shrink-0 border-r border-[#E2E8F0] bg-[#FFFFFF] min-h-[calc(100vh-3.5rem)] justify-between p-4"
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
              className={`w-full min-h-[44px] px-3.5 py-2.5 rounded-xl text-sm font-semibold flex items-center justify-between transition-colors ${
                isActive
                  ? 'bg-[#FEF3C7] text-[#B45309]'
                  : 'text-[#475569] hover:bg-[#F8FAFC] hover:text-[#0F172A]'
              }`}
            >
              <span className="flex items-center gap-3">
                <Icon className="w-4 h-4 shrink-0" />
                <span>{t.nav[id]}</span>
              </span>
              {id === 'materials' && (
                <span
                  className={`font-mono-tabular text-xs px-2 py-0.5 rounded-full ${
                    isActive
                      ? 'bg-[#D97706]/15 text-[#B45309]'
                      : 'bg-[#F1F5F9] text-[#64748B]'
                  }`}
                >
                  {state.materials.filter((m) => !m.isArchived).length}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      <div className="pt-4 border-t border-[#E2E8F0] text-xs text-[#64748B] space-y-1">
        <p className="font-semibold text-[#0F172A]">{t.appSubtitle}</p>
        <p className="font-mono-tabular text-[#64748B]">
          {t.currencyLabel} · {state.materials.filter((m) => !m.isArchived).length}{' '}
          {t.kpis.registeredMaterials}
        </p>
      </div>
    </aside>
  );
};

/**
 * Mobile & Tablet 5-Tab Bottom Navigation Bar (< 1024px)
 * Uses concise, unclipped labels for one-handed mobile ergonomics.
 */
export const MobileBottomNavigation: React.FC = () => {
  const { activeTab, setActiveTab, language } = useErpStore();

  const getShortTabLabel = (id: AppRouteTab): string => {
    if (language === 'am') {
      switch (id) {
        case 'dashboard':
          return 'ዳሽቦርድ';
        case 'materials':
          return 'ዕቃዎች';
        case 'pos':
          return 'ሽያጭ';
        case 'stock-in':
          return 'ክምችት';
        case 'audit-log':
          return 'ተጨማሪ';
      }
    }
    if (language === 'om') {
      switch (id) {
        case 'dashboard':
          return 'Daashboordii';
        case 'materials':
          return 'Meeshaalee';
        case 'pos':
          return 'Gurgurtaa';
        case 'stock-in':
          return 'Kuusaa';
        case 'audit-log':
          return 'Dabalata';
      }
    }
    switch (id) {
      case 'dashboard':
        return 'Dashboard';
      case 'materials':
        return 'Materials';
      case 'pos':
        return 'Sales';
      case 'stock-in':
        return 'Inventory';
      case 'audit-log':
        return 'More';
    }
  };

  return (
    <nav
      aria-label="Mobile Store Navigation"
      className="lg:hidden fixed bottom-0 inset-x-0 z-30 h-16 bg-[#FFFFFF] border-t border-[#E2E8F0] grid grid-cols-5 px-1"
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
                ? 'text-[#B45309] font-bold'
                : 'text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            <span
              className={`px-3 py-0.5 rounded-full transition-colors ${
                isActive ? 'bg-[#FEF3C7]' : ''
              }`}
            >
              <Icon className="w-4 h-4 shrink-0" />
            </span>
            <span className="text-[10.5px] leading-tight truncate max-w-full">
              {getShortTabLabel(id)}
            </span>
          </button>
        );
      })}
    </nav>
  );
};
