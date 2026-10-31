import React from 'react';
import { AlertTriangle, CheckCircle2, X } from 'lucide-react';
import { useErpStore } from '../context/ErpContext';

export const StatusBanner: React.FC = () => {
  const {
    error,
    clearError,
    successMessage,
    clearSuccessMessage,
    refreshState,
    t,
  } = useErpStore();

  return (
    <>
      {error && (
        <div
          role="alert"
          className="mb-4 rounded-lg border border-[#B91C1C]/30 bg-[#FEF2F2] p-4 text-[#B91C1C] flex items-start justify-between gap-3"
        >
          <div className="flex items-start gap-2.5 min-w-0">
            <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
            <div className="text-sm space-y-1">
              <p className="font-semibold">
                {t.errors[error.code] || error.message}
              </p>
              <p className="text-xs text-[#B91C1C]/85">{error.message}</p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={() => void refreshState()}
              className="px-3 py-1.5 text-xs font-semibold rounded-md bg-[#FFFFFF] border border-[#B91C1C]/30 text-[#B91C1C] hover:bg-[#FEF2F2]"
            >
              {t.shell.retryAction}
            </button>
            <button
              type="button"
              onClick={clearError}
              aria-label="Dismiss error"
              className="p-1 rounded-md hover:bg-[#B91C1C]/10"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {successMessage && (
        <div
          role="status"
          className="mb-4 rounded-lg border border-[#166534]/30 bg-[#F0FDF4] px-4 py-3 text-[#166534] flex items-center justify-between gap-3"
        >
          <div className="flex items-center gap-2.5 text-sm font-medium">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMessage}</span>
          </div>
          <button
            type="button"
            onClick={clearSuccessMessage}
            aria-label="Dismiss notification"
            className="p-1 rounded-md hover:bg-[#166534]/10"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </>
  );
};
