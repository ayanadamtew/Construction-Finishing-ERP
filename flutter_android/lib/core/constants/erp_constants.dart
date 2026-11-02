import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum MaterialCategory {
  rebar('rebar'),
  cement('cement'),
  tiles('tiles'),
  paint('paint'),
  hardware('hardware'),
  other('other');

  final String code;
  const MaterialCategory(this.code);

  static MaterialCategory fromCode(String raw) {
    return MaterialCategory.values.firstWhere(
      (c) => c.code == raw,
      orElse: () => MaterialCategory.other,
    );
  }
}

enum MaterialUnit {
  pcs('pcs'),
  bars('bars'),
  bags('bags'),
  boxes('boxes'),
  buckets('buckets'),
  kg('kg'),
  m('m'),
  liters('liters');

  final String code;
  const MaterialUnit(this.code);

  static MaterialUnit fromCode(String raw) {
    return MaterialUnit.values.firstWhere(
      (u) => u.code == raw,
      orElse: () => MaterialUnit.pcs,
    );
  }
}

enum UserRole {
  admin('admin'),
  staff('staff');

  final String code;
  const UserRole(this.code);

  static UserRole fromCode(String raw) {
    return UserRole.values.firstWhere(
      (r) => r.code == raw.toLowerCase(),
      orElse: () => UserRole.staff,
    );
  }
}


/// Modern Minimal Material 3 Design System Palette
class ErpColors {
  // Primary warm amber/orange accent
  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFFEF3C7);
  static const Color primarySoft = Color(0xFFFFFBEB);

  // Neutral surfaces & backgrounds
  static const Color bgPrimary = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  // Typography hierarchy
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Backward-compatible aliases
  static const Color accentTerracotta = primary;
  static const Color accentHover = primaryDark;

  // Borders & dividers
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Semantic statuses
  static const Color statusSuccess = Color(0xFF16A34A);
  static const Color statusSuccessBg = Color(0xFFDCFCE7);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusDanger = Color(0xFFDC2626);
  static const Color statusDangerBg = Color(0xFFFEE2E2);
}

final NumberFormat _etbFormatter = NumberFormat('#,##0.00', 'en_US');
final NumberFormat _qtyFormatter = NumberFormat('#,##0.##', 'en_US');

/// Rounds a floating-point monetary or quantity value to 2 decimal places (`BR-006`).
double round2(num value) {
  return ((value.toDouble() + 1e-9) * 100).roundToDouble() / 100.0;
}

/// Formats an Ethiopian Birr (`ETB`) value to 2 decimal places (`ETB 1,450.00`).
String formatETB(num value) {
  return 'ETB ${_etbFormatter.format(round2(value))}';
}

/// Formats a quantity cleanly (`45` or `45.25`).
String formatQty(num value) {
  return _qtyFormatter.format(round2(value));
}
