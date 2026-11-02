import React, { useState } from 'react';
import { Globe, LogOut, RefreshCw, Settings, ShieldCheck } from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { LanguageCode } from '../types/erp';
import { UsersAndCategoriesModal } from './UsersAndCategoriesModal';

const LANGUAGE_OPTIONS: {
  code: LanguageCode;
  label: string;
  native: string;
}[] = [
  { code: 'en', label: 'EN', native: 'English' },
  { code: 'am', label: 'አማ', native: 'አማርኛ' },
  { code: 'om', label: 'OM', native: 'Afaan Oromoo' },
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
  const [isMenuOpen, setIsMenuOpen] = useState<boolean>(false);

  const activeLangObj =
    LANGUAGE_OPTIONS.find((l) => l.code === language) ?? LANGUAGE_OPTIONS[0];

  return (
    <>
      <header className="sticky top-0 z-30 h-14 bg-[#FFFFFF] border-b border-[#E2E8F0] px-4 lg:px-8 flex items-center justify-between gap-3">
        {/* Left: Clean Store Brand Title */}
        <div className="min-w-0 flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-[#FEF3C7] text-[#B45309] flex items-center justify-center font-bold text-xs shrink-0">
            EFA
          </div>
          <h1 className="text-sm sm:text-base font-bold tracking-tight text-[#0F172A] truncate">
            {t.appTitle}
          </h1>
        </div>

        {/* Right: Uncrowded Actions (Compact Account & Settings Menu) */}
        <div className="flex items-center gap-2 shrink-0 relative">
          <button
            type="button"
            onClick={() => void refreshState()}
            disabled={isLoading}
            aria-label={t.shell.refreshState}
            className="min-h-[38px] min-w-[38px] px-2.5 py-1.5 text-xs font-medium rounded-lg border border-[#E2E8F0] bg-[#FFFFFF] text-[#475569] hover:bg-[#F8FAFC] transition-colors flex items-center justify-center gap-1.5 disabled:opacity-50"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 ${
                isLoading ? 'animate-spin text-[#D97706]' : 'text-[#475569]'
              }`}
            />
            <span className="hidden md:inline">{t.shell.refreshState}</span>
          </button>

          {currentUser && (
            <button
              type="button"
              onClick={() => setIsMenuOpen((prev) => !prev)}
              aria-label="Open Account and Settings Menu"
              aria-expanded={isMenuOpen}
              className="min-h-[38px] px-2.5 py-1.5 text-xs font-semibold rounded-full border border-[#E2E8F0] bg-[#F8FAFC] text-[#0F172A] hover:bg-[#F1F5F9] transition-colors flex items-center gap-2"
            >
              <span className="w-5 h-5 rounded-full bg-[#D97706] text-white text-[10px] font-bold flex items-center justify-center shrink-0">
                {currentUser.displayName.charAt(0).toUpperCase()}
              </span>
              <span className="hidden sm:inline max-w-[140px] truncate">
                {currentUser.displayName}
              </span>
              <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-[#FEF3C7] text-[#B45309]">
                {activeLangObj.label}
              </span>
            </button>
          )}

          {/* Compact Account, Language & Admin Dropdown Menu */}
          {isMenuOpen && currentUser && (
            <div className="absolute right-0 top-12 w-64 bg-[#FFFFFF] border border-[#E2E8F0] rounded-xl shadow-lg p-3 z-50 space-y-3">
              <div className="pb-2.5 border-b border-[#E2E8F0]">
                <p className="text-xs font-bold text-[#0F172A] truncate">
                  {currentUser.displayName}
                </p>
                <p className="text-[11px] text-[#64748B] truncate">
                  @{currentUser.username} · {currentUser.role.toUpperCase()}
                </p>
              </div>

              {/* Language Switcher inside Menu */}
              <div className="space-y-1.5">
                <p className="text-[11px] font-semibold text-[#64748B] flex items-center gap-1">
                  <Globe className="w-3 h-3" />
                  <span>{t.languageLabel}</span>
                </p>
                <div className="grid grid-cols-3 gap-1 bg-[#F1F5F9] p-1 rounded-lg">
                  {LANGUAGE_OPTIONS.map((opt) => {
                    const isActive = language === opt.code;
                    return (
                      <button
                        key={opt.code}
                        type="button"
                        onClick={() => {
                          setLanguage(opt.code);
                          setIsMenuOpen(false);
                        }}
                        className={`min-h-[32px] px-2 py-1 text-xs font-semibold rounded-md transition-colors ${
                          isActive
                            ? 'bg-[#FFFFFF] text-[#B45309] shadow-xs'
                            : 'text-[#475569] hover:text-[#0F172A]'
                        }`}
                      >
                        {opt.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="space-y-1 pt-1 border-t border-[#E2E8F0]">
                <button
                  type="button"
                  onClick={() => {
                    setIsMenuOpen(false);
                    setIsAdminModalOpen(true);
                  }}
                  className="w-full min-h-[38px] px-2.5 py-1.5 text-xs font-medium rounded-lg text-[#0F172A] hover:bg-[#F8FAFC] flex items-center gap-2"
                >
                  {currentUser.role === 'admin' ? (
                    <ShieldCheck className="w-4 h-4 text-[#D97706]" />
                  ) : (
                    <Settings className="w-4 h-4 text-[#475569]" />
                  )}
                  <span>Users & Categories</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setIsMenuOpen(false);
                    void logout();
                  }}
                  className="w-full min-h-[38px] px-2.5 py-1.5 text-xs font-semibold rounded-lg text-[#DC2626] hover:bg-[#FEE2E2]/50 flex items-center gap-2"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Logout</span>
                </button>
              </div>

              {/* About EFA Section */}
              <div className="pt-2 border-t border-[#E2E8F0] text-[11px] text-[#64748B] space-y-0.5">
                <p className="font-semibold text-[#0F172A]">
                  About EFA · v1.0.0 (Build 1)
                </p>
                <p>Developer: Ayana Damtew</p>
                <p>Phone: +251973395537</p>
              </div>
            </div>
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
