/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { AuditAndLogView } from './components/AuditAndLogView';
import { DashboardView } from './components/DashboardView';
import { Header } from './components/Header';
import { LoginView } from './components/LoginView';
import { MaterialsView } from './components/MaterialsView';
import {
  DesktopNavigationRail,
  MobileBottomNavigation,
} from './components/Navigation';
import { SalesPosView } from './components/SalesPosView';
import { StatusBanner } from './components/StatusBanner';
import { StockInView } from './components/StockInView';
import { ErpProvider, useErpStore } from './context/ErpContext';

const ErpWorkspaceShell: React.FC = () => {
  const { activeTab, currentUser, isAuthChecking, t } = useErpStore();

  if (isAuthChecking) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F6F5F1] text-[#14171A] p-6">
        <p className="text-sm font-medium text-[#4A5056]">
          {t.shell.loadingState}
        </p>
      </div>
    );
  }

  if (!currentUser) {
    return <LoginView />;
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#F6F5F1] text-[#14171A]">
      <Header />

      <div className="flex-1 flex">
        <DesktopNavigationRail />

        <main className="flex-1 max-w-[1360px] w-full mx-auto p-4 sm:p-6 lg:p-8 pb-24 lg:pb-8">
          <StatusBanner />

          {activeTab === 'materials' ? (
            <MaterialsView />
          ) : activeTab === 'pos' ? (
            <SalesPosView />
          ) : activeTab === 'stock-in' ? (
            <StockInView />
          ) : activeTab === 'audit-log' ? (
            <AuditAndLogView />
          ) : (
            <DashboardView />
          )}
        </main>
      </div>

      <MobileBottomNavigation />
    </div>
  );
};

export default function App() {
  return (
    <ErpProvider>
      <ErpWorkspaceShell />
    </ErpProvider>
  );
}
