import 'package:flutter/material.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../../l10n/erp_localizations.dart';

enum ErpButtonVariant { primary, secondary, danger, ghost }

/// Reusable Material 3 button with consistent touch target and overflow-safe label.
class ErpButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ErpButtonVariant variant;
  final bool isFullWidth;
  final bool isCompact;

  const ErpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ErpButtonVariant.primary,
    this.isFullWidth = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final minHeight = isCompact ? 36.0 : 46.0;
    final hPad = isCompact ? 12.0 : 16.0;
    final vPad = isCompact ? 6.0 : 12.0;
    final fontSize = isCompact ? 12.0 : 13.0;

    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: isCompact ? 15 : 18),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    switch (variant) {
      case ErpButtonVariant.primary:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ErpColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 44, minHeight),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: child,
        );
      case ErpButtonVariant.danger:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ErpColors.statusDanger,
            backgroundColor: ErpColors.statusDangerBg.withValues(alpha: 0.35),
            side: BorderSide(
              color: ErpColors.statusDanger.withValues(alpha: 0.35),
            ),
            minimumSize: Size(isFullWidth ? double.infinity : 44, minHeight),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: child,
        );
      case ErpButtonVariant.ghost:
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ErpColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 44, minHeight),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
          child: child,
        );
      case ErpButtonVariant.secondary:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ErpColors.textPrimary,
            backgroundColor: ErpColors.surfaceCard,
            side: const BorderSide(color: ErpColors.borderSubtle),
            minimumSize: Size(isFullWidth ? double.infinity : 44, minHeight),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: child,
        );
    }
  }
}

/// Reusable Material 3 Input Field
class ErpInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  const ErpInputField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ErpColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 19, color: ErpColors.textMuted)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Reusable Search Bar with clear button
class ErpSearchBar extends StatelessWidget {
  final String hintText;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const ErpSearchBar({
    super.key,
    required this.hintText,
    required this.value,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 13.5,
        color: ErpColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: ErpColors.textMuted,
        ),
        suffixIcon: value.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: ErpColors.textMuted,
                ),
                onPressed: onClear ?? () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: ErpColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ErpColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

/// Compact, overflow-safe Summary Indicator Card for Dashboard & Reports
class ErpSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const ErpSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor = ErpColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ErpColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ErpColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: ErpColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ErpColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: ErpColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle Semantic Status Label
class ErpStatusLabel extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;

  const ErpStatusLabel({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  });

  factory ErpStatusLabel.stock(MaterialItem item, ErpLocalizations i18n) {
    if (item.isArchived) {
      return ErpStatusLabel(
        text: i18n.t('badgeArchived'),
        textColor: ErpColors.textSecondary,
        backgroundColor: ErpColors.surfaceElevated,
      );
    }
    if (item.isOutOfStock) {
      return ErpStatusLabel(
        text: i18n.t('statusOutStock'),
        textColor: ErpColors.statusDanger,
        backgroundColor: ErpColors.statusDangerBg,
      );
    }
    if (item.isLowStock) {
      return ErpStatusLabel(
        text: i18n.t('statusLowStock'),
        textColor: ErpColors.statusWarning,
        backgroundColor: ErpColors.statusWarningBg,
      );
    }
    return ErpStatusLabel(
      text: i18n.t('statusInStock'),
      textColor: ErpColors.statusSuccess,
      backgroundColor: ErpColors.statusSuccessBg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Section Header with optional count badge and "View All" action
class ErpSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? badgeColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErpSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.badgeColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: ErpColors.textPrimary,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? ErpColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? ErpColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ErpColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(44, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

/// Reusable Material List Item (used on Dashboard Low-Stock & Material Catalog)
class ErpMaterialListItem extends StatelessWidget {
  final MaterialItem material;
  final String categoryLabel;
  final ErpLocalizations i18n;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onQuickAction;
  final IconData? quickActionIcon;
  final String? quickActionTooltip;

  const ErpMaterialListItem({
    super.key,
    required this.material,
    required this.categoryLabel,
    required this.i18n,
    this.compact = false,
    this.onTap,
    this.onEdit,
    this.onQuickAction,
    this.quickActionIcon,
    this.quickActionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final unitStr = i18n.unitLabel(material.unit.code);
    final isLow = !material.isArchived && material.isLowStock;

    return Material(
      color: material.isArchived
          ? ErpColors.surfaceElevated.withValues(alpha: 0.6)
          : ErpColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLow
              ? ErpColors.statusWarning.withValues(alpha: 0.4)
              : ErpColors.borderSubtle,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            material.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: material.isArchived
                                  ? ErpColors.textMuted
                                  : ErpColors.textPrimary,
                              decoration: material.isArchived
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ErpStatusLabel.stock(material, i18n),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      material.specs.trim().isNotEmpty
                          ? '$categoryLabel • ${material.specs}'
                          : categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ErpColors.textSecondary,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${i18n.t('lblPrice')}: ${formatETB(material.defaultSellingPrice)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ErpColors.primaryDark,
                            ),
                          ),
                          Text(
                            '${i18n.t('lblCost')}: ${formatETB(material.unitCost)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ErpColors.textMuted,
                            ),
                          ),
                          Text(
                            '${i18n.t('lblMin')}: ${formatQty(material.minStockLevel)} $unitStr',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ErpColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Right Stock Quantity & Minimum
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${formatQty(material.currentStock)} $unitStr',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: material.isOutOfStock
                          ? ErpColors.statusDanger
                          : (isLow
                              ? ErpColors.statusWarning
                              : ErpColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${i18n.t('lblMin')}: ${formatQty(material.minStockLevel)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ErpColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (onQuickAction != null && quickActionIcon != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: quickActionTooltip,
                  onPressed: onQuickAction,
                  icon: Icon(
                    quickActionIcon,
                    size: 19,
                    color: ErpColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Transaction List Item for Recent Sales & History
class ErpTransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amountText;
  final String? secondaryAmountText;
  final bool isReversed;
  final String? reversedBadgeText;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const ErpTransactionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    this.secondaryAmountText,
    this.isReversed = false,
    this.reversedBadgeText,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isReversed
          ? ErpColors.surfaceElevated.withValues(alpha: 0.6)
          : ErpColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isReversed
              ? ErpColors.statusDanger.withValues(alpha: 0.35)
              : ErpColors.borderSubtle,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isReversed
                                  ? ErpColors.textMuted
                                  : ErpColors.textPrimary,
                              decoration: isReversed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isReversed && reversedBadgeText != null) ...[
                          const SizedBox(width: 6),
                          ErpStatusLabel(
                            text: reversedBadgeText!,
                            textColor: ErpColors.statusDanger,
                            backgroundColor: ErpColors.statusDangerBg,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: ErpColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isReversed
                          ? ErpColors.textMuted
                          : ErpColors.textPrimary,
                      decoration:
                          isReversed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (secondaryAmountText != null)
                    Text(
                      secondaryAmountText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ErpColors.statusSuccess,
                      ),
                    ),
                ],
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 8),
                trailingAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean Segmented Control for sub-navigation (Inventory & More)
class ErpSegmentedControl extends StatelessWidget {
  final List<({String label, IconData icon})> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ErpSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ErpColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ErpColors.borderSubtle),
      ),
      child: Row(
        children: List.generate(segments.length, (idx) {
          final seg = segments[idx];
          final active = idx == selectedIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? ErpColors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seg.icon,
                      size: 16,
                      color: active
                          ? ErpColors.primaryDark
                          : ErpColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        seg.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? ErpColors.textPrimary
                              : ErpColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Minimal Empty State
class ErpEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErpEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: ErpColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ErpColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ErpColors.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 22, color: ErpColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: ErpColors.textPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: ErpColors.textSecondary,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            ErpButton(
              label: actionLabel!,
              icon: Icons.add_rounded,
              isCompact: true,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Minimal Loading State
class ErpLoadingState extends StatelessWidget {
  final String message;

  const ErpLoadingState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ErpColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: ErpColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Bottom Sheet Wrapper with Drag Handle and Header
class ErpBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ErpBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ErpColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ErpColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ErpColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ErpColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: ErpColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: ErpColors.borderSubtle),
            child,
          ],
        ),
      ),
    );
  }
}
