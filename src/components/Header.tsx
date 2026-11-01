import React, { useState } from 'react';
import { LogOut, RefreshCw, Settings, ShieldCheck } from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { LanguageCode } from '../types/erp';
import { UsersAndCategoriesModal } from './UsersAndCategoriesModal';

const LANGUAGE_OPTIONS: {
  code: LanguageCode;
  label: string;
  ariaLabel: string;
}[] = [
  { code: 'en', label: 'EN', ariaLabel: 'Switch language to English' },
  { code: 'am', label: 'አማ', ariaLabel: 'Switch language to Amharic' },
  { code: 'om', label: 'ORO', ariaLabel: 'Switch language to Afan Oromo' },
];

export const Header: React.FC = () => {
  const {
    language,
    setLanguage,
    t,
    isLoading,
    refreshState,
    currentUser,
    logout,
  } = useErpStore();

  const [isAdminModalOpen, setIsAdminModalOpen] = useState<boolean>(false);

  return (
    <>
      <header className="sticky top-0 z-30 h-14 bg-[#FFFFFF] border-b border-[#DCD9D0] px-4 lg:px-8 flex items-center justify-between gap-4">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="text-base sm:text-lg font-bold tracking-tight text-[#14171A] truncate">
              {t.appTitle}
            </h1>
            <span aria-hidden="true" className="hidden sm:inline text-[#6E757C]">
              ·
            </span>
            <span className="hidden md:inline text-xs text-[#4A5056] truncate">
              {t.shell.syncStatusConnected}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-2.5 shrink-0">
          {currentUser && (
            <button
              type="button"
              onClick={() => setIsAdminModalOpen(true)}
              aria-label="Open Users and Categories Administration"
              className="min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#F6F5F1] text-[#14171A] hover:bg-[#ECEAE3] transition-colors flex items-center gap-1.5"
            >
              {currentUser.role === 'admin' ? (
                <ShieldCheck className="w-3.5 h-3.5 text-[#B84A14]" />
              ) : (
                <Settings className="w-3.5 h-3.5 text-[#4A5056]" />
              )}
              <span className="hidden sm:inline font-semibold">
                {currentUser.displayName}
              </span>
              <span className="text-[11px] uppercase text-[#6E757C]">
                ({currentUser.role})
              </span>
            </button>
          )}

          <button
            type="button"
            onClick={() => void refreshState()}
            disabled={isLoading}
            aria-label={t.shell.refreshState}
            className="min-h-[38px] px-3 py-1.5 text-xs font-medium rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1] transition-colors flex items-center gap-1.5 disabled:opacity-50"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 ${
                isLoading ? 'animate-spin text-[#B84A14]' : 'text-[#4A5056]'
              }`}
            />
            <span className="hidden lg:inline">{t.shell.refreshState}</span>
          </button>

          {/* Segmented Language Control */}
          <div
            role="group"
            aria-label={t.languageLabel}
            className="flex items-center gap-0.5 p-1 bg-[#ECEAE3] rounded-md border border-[#DCD9D0]"
          >
            {LANGUAGE_OPTIONS.map((opt) => {
              const isActive = language === opt.code;
              return (
                <button
                  key={opt.code}
                  type="button"
                  aria-label={opt.ariaLabel}
                  aria-pressed={isActive}
                  onClick={() => setLanguage(opt.code)}
                  className={`min-h-[32px] px-2 py-1 text-xs font-semibold rounded transition-colors ${
                    isActive
                      ? 'bg-[#B84A14] text-[#FFFFFF]'
                      : 'text-[#4A5056] hover:text-[#14171A]'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>

          {currentUser && (
            <button
              type="button"
              onClick={() => void logout()}
              aria-label="Sign out"
              className="min-h-[38px] px-2.5 py-1.5 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#B91C1C] hover:bg-[#FEF2F2] transition-colors flex items-center gap-1"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Logout</span>
            </button>
          )}
        </div>
      </header>

      <UsersAndCategoriesModal
        isOpen={isAdminModalOpen}
        initialSection={currentUser?.role === 'admin' ? 'users' : 'categories'}
        onClose={() => setIsAdminModalOpen(false)}
      />
    </>
  );
};
