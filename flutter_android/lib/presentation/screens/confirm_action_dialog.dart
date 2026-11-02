import 'package:flutter/material.dart';
import '../../core/constants/erp_constants.dart';
import '../../l10n/erp_localizations.dart';
import '../widgets/erp_components.dart';

/// Reusable confirmation dialog that displays the exact record name/ID before
/// executing a destructive or reversal action.
class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String recordName;
  final String description;
  final String confirmLabel;
  final Color confirmColor;
  final bool requireReason;
  final ErpLocalizations i18n;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.recordName,
    required this.description,
    required this.confirmLabel,
    this.confirmColor = ErpColors.statusDanger,
    this.requireReason = false,
    required this.i18n,
  });

  static Future<({bool confirmed, String reason})?> show(
    BuildContext context, {
    required String title,
    required String recordName,
    required String description,
    required String confirmLabel,
    Color confirmColor = ErpColors.statusDanger,
    bool requireReason = false,
    required ErpLocalizations i18n,
  }) {
    return showDialog<({bool confirmed, String reason})>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        recordName: recordName,
        description: description,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        requireReason: requireReason,
        i18n: i18n,
      ),
    );
  }

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = widget.i18n;
    return AlertDialog(
      backgroundColor: ErpColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ErpColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ErpColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ErpColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.t('targetRecordLabel').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.recordName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ErpColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: ErpColors.textSecondary,
              ),
            ),
            if (widget.requireReason) ...[
              const SizedBox(height: 12),
              ErpInputField(
                controller: _reasonCtrl,
                label: i18n.t('reversalReasonLabel'),
                hintText: i18n.t('reversalReasonHint'),
                errorText: _errorText,
                maxLines: 2,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(i18n.t('btnCancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final reason = _reasonCtrl.text.trim();
            if (widget.requireReason && reason.isEmpty) {
              setState(() {
                _errorText = 'Reversal reason is required.';
              });
              return;
            }
            Navigator.of(context).pop((confirmed: true, reason: reason));
          },
          child: Text(
            widget.confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
