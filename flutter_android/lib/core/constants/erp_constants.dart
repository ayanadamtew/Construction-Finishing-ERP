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

/// Warm Industrial Ledger Design System palette (`docs/UI_UX_SPEC.md` Section 2)
class ErpColors {
  static const Color bgPrimary = Color(0xFFF6F4F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEDEAE2);
  static const Color textPrimary = Color(0xFF141413);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);
  static const Color accentTerracotta = Color(0xFFC85A17);
  static const Color accentHover = Color(0xFF9A3412);
  static const Color borderSubtle = Color(0xFFD6D3CD);
  static const Color borderStrong = Color(0xFFA8A29E);

  static const Color statusSuccess = Color(0xFF166534);
  static const Color statusSuccessBg = Color(0xFFDCFCE7);
  static const Color statusWarning = Color(0xFFB45309);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusDanger = Color(0xFFB91C1C);
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
