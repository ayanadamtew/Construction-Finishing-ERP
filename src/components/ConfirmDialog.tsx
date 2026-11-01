import React, { useEffect, useState } from 'react';
import { AlertTriangle, X } from 'lucide-react';
import { AppDomainError } from '../utils/errors';

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  recordName: string;
  description: string;
  prohibitedExplanation?: string;
  confirmLabel: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'primary';
  requireReason?: boolean;
  reasonLabel?: string;
  reasonPlaceholder?: string;
  onConfirm: (reason: string) => Promise<void>;
  onClose: () => void;
}

export const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  isOpen,
  title,
  recordName,
  description,
  prohibitedExplanation,
  confirmLabel,
  cancelLabel = 'Cancel',
  variant = 'danger',
  requireReason = false,
  reasonLabel = 'Reversal Reason *',
  reasonPlaceholder = 'Enter the reason for this reversal (required for audit trail)...',
  onConfirm,
  onClose,
}) => {
  const [reason, setReason] = useState<string>('');
  const [localError, setLocalError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  useEffect(() => {
    if (isOpen) {
      setReason('');
      setLocalError(null);
      setIsSubmitting(false);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleConfirm = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);

    if (requireReason && !reason.trim()) {
      setLocalError('Please enter a reason to record in the audit trail.');
      return;
    }

    setIsSubmitting(true);
    try {
      await onConfirm(reason.trim());
      onClose();
    } catch (err) {
      if (err instanceof AppDomainError) {
        setLocalError(err.message);
      } else {
        setLocalError(
          err instanceof Error ? err.message : 'Operation could not be completed.'
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const buttonColorClass =
    variant === 'danger'
      ? 'bg-[#B91C1C] text-[#FFFFFF] hover:bg-[#991B1B]'
      : variant === 'warning'
        ? 'bg-[#9A3412] text-[#FFFFFF] hover:bg-[#7C2D12]'
        : 'bg-[#B84A14] text-[#FFFFFF] hover:bg-[#963B0E]';

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-[#14171A]/50 p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="confirm-dialog-title"
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md bg-[#FFFFFF] border border-[#DCD9D0] rounded-lg overflow-hidden shadow-lg"
      >
        <div className="px-5 py-4 border-b border-[#ECEAE3] flex items-start justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <AlertTriangle
              className={`w-5 h-5 shrink-0 ${
                variant === 'danger' ? 'text-[#B91C1C]' : 'text-[#9A3412]'
              }`}
            />
            <h2
              id="confirm-dialog-title"
              className="text-base font-bold text-[#14171A]"
            >
              {title}
            </h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={cancelLabel}
            className="min-h-[32px] min-w-[32px] rounded flex items-center justify-center text-[#4A5056] hover:bg-[#F6F5F1]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <form onSubmit={(e) => void handleConfirm(e)} className="p-5 space-y-4">
          <div className="p-3 rounded-md bg-[#F6F5F1] border border-[#DCD9D0]">
            <p className="text-[11px] font-semibold uppercase tracking-wider text-[#6E757C]">
              Target Record
            </p>
            <p className="text-sm font-bold text-[#14171A] mt-0.5 break-words">
              {recordName}
            </p>
          </div>

          <p className="text-sm text-[#4A5056] leading-relaxed">{description}</p>

          {prohibitedExplanation && (
            <div className="p-3 rounded-md bg-[#FFF7ED] border border-[#9A3412]/30 text-xs text-[#9A3412]">
              {prohibitedExplanation}
            </div>
          )}

          {requireReason && (
            <div>
              <label
                htmlFor="confirm-dialog-reason-input"
                className="block text-xs font-semibold text-[#14171A] mb-1.5"
              >
                {reasonLabel}
              </label>
              <input
                id="confirm-dialog-reason-input"
                type="text"
                required
                maxLength={200}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder={reasonPlaceholder}
                className="w-full min-h-[42px] px-3 py-2 text-sm bg-[#FFFFFF] border border-[#DCD9D0] rounded-md text-[#14171A] placeholder:text-[#6E757C] focus:outline-none focus:border-[#B84A14]"
              />
            </div>
          )}

          {localError && (
            <div
              role="alert"
              className="p-3 rounded-md bg-[#FEF2F2] border border-[#B91C1C]/30 text-xs text-[#B91C1C]"
            >
              {localError}
            </div>
          )}

          <div className="pt-2 border-t border-[#ECEAE3] flex items-center justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="min-h-[40px] px-4 py-2 text-xs font-semibold rounded-md border border-[#DCD9D0] bg-[#FFFFFF] text-[#14171A] hover:bg-[#F6F5F1]"
            >
              {cancelLabel}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className={`min-h-[40px] px-4 py-2 text-xs font-semibold rounded-md transition-colors disabled:opacity-50 ${buttonColorClass}`}
            >
              {isSubmitting ? 'Processing...' : confirmLabel}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
