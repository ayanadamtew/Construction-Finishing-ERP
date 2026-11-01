import React, { useState } from 'react';
import { AlertTriangle, Eye, EyeOff, Lock, ShieldCheck } from 'lucide-react';
import { useErpStore } from '../context/ErpContext';
import { LanguageCode } from '../types/erp';
import { AppDomainError } from '../utils/errors';

const LANGUAGE_OPTIONS: { code: LanguageCode; label: string }[] = [
  { code: 'en', label: 'EN' },
  { code: 'am', label: 'አማ' },
  { code: 'om', label: 'ORO' },
];

export const LoginView: React.FC = () => {
  const { login, language, setLanguage, t } = useErpStore();

  const [username, setUsername] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const trimmedUser = username.trim();
    if (!trimmedUser) {
      setErrorMessage('Please enter your pre-registered username or email.');
      return;
    }
    if (!password || !password.trim()) {
      setErrorMessage('Please enter your password.');
      return;
    }

    setIsSubmitting(true);
    try {
      await login({
        username: trimmedUser,
        password,
      });
    } catch (err) {
      if (err instanceof AppDomainError) {
        setErrorMessage(err.message || t.errors[err.code]);
      } else {
        setErrorMessage(
          err instanceof Error
            ? err.message
            : 'Unable to sign in. Please verify your credentials.'
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F6F5F1] text-[#14171A] flex flex-col justify-between p-4 sm:p-6">
      {/* Top Bar with Brand & Language Switcher */}
      <header className="max-w-md w-full mx-auto flex items-center justify-between pt-2">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-md bg-[#B84A14] text-[#FFFFFF] flex items-center justify-center font-bold text-sm">
            ERP
          </div>
          <span className="text-sm font-bold text-[#14171A]">{t.appTitle}</span>
        </div>

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
                aria-pressed={isActive}
                onClick={() => setLanguage(opt.code)}
                className={`min-h-[30px] px-2.5 py-0.5 text-xs font-semibold rounded transition-colors ${
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
      </header>

      {/* Centered Login Card */}
      <main className="max-w-md w-full mx-auto my-8">
        <div className="bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden shadow-sm">
          <div className="p-6 border-b border-[#ECEAE3] space-y-1.5">
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-[#B84A14]">
              <ShieldCheck className="w-4 h-4" />
              <span>Authorized Store Access</span>
            </div>
            <h1 className="text-xl font-bold text-[#14171A]">
              Sign In to {t.appTitle}
            </h1>
            <p className="text-xs text-[#4A5056]">
              Enter your pre-registered store credentials to access inventory,
              POS sales, Stock-In deliveries, and ground-stock audits.
            </p>
          </div>

          <form
            onSubmit={(e) => void handleSubmit(e)}
            noValidate
            className="p-6 space-y-4"
          >
            {errorMessage && (
              <div
                role="alert"
                className="rounded-md border border-[#B91C1C]/30 bg-[#FEF2F2] p-3 text-xs text-[#B91C1C] flex items-start gap-2"
              >
                <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                <span>{errorMessage}</span>
              </div>
            )}

            <div>
              <label
                htmlFor="login-username-input"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                Username or Email *
              </label>
              <input
                id="login-username-input"
                type="text"
                autoComplete="username"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="e.g., admin"
                className="w-full min-h-[44px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
              />
            </div>

            <div>
              <label
                htmlFor="login-password-input"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                Password *
              </label>
              <div className="relative">
                <input
                  id="login-password-input"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  className="w-full min-h-[44px] pl-3 pr-11 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((prev) => !prev)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  className="absolute right-2 top-1/2 -translate-y-1/2 min-h-[34px] min-w-[34px] rounded flex items-center justify-center text-[#4A5056] hover:text-[#14171A] hover:bg-[#F6F5F1]"
                >
                  {showPassword ? (
                    <EyeOff className="w-4 h-4" />
                  ) : (
                    <Eye className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full min-h-[46px] px-4 py-2.5 text-sm font-semibold rounded-md bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E] transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <Lock className="w-4 h-4" />
              <span>{isSubmitting ? 'Signing In...' : 'Sign In'}</span>
            </button>
          </form>

          <div className="px-6 py-3.5 bg-[#ECEAE3] border-t border-[#DCD9D0] text-[11px] text-[#4A5056]">
            Public self-registration is disabled. Authorized accounts are
            provisioned exclusively by the Store Administrator.
          </div>
        </div>
      </main>

      <footer className="max-w-md w-full mx-auto text-center text-xs text-[#6E757C] pb-2">
        {t.appTitle} · {t.shell.syncStatusConnected}
      </footer>
    </div>
  );
};
