import 'package:flutter/material.dart';

/// Application & Developer Metadata read from project configuration (`pubspec.yaml`).
class ErpAppInfo {
  ErpAppInfo._();

  static const String appName = 'EFA';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String fullVersion = '1.0.0+1';
  static const String developerName = 'Ayana Damtew';
  static const String developerPhone = '+251973395537';
  static const String appDescription =
      'Construction & Finishing Material Store Mobile ERP & Inventory Management System (SKU-Free, ETB Currency, Trilingual English/Amharic/Afan Oromo).';
}

/// Restrained, modern commercial color palette (Warm Amber Accent + Slate Neutral Surfaces).
class ErpColors {
  ErpColors._();

  // Brand Primary (Warm Amber / Terracotta)
  static const Color primary = Color(0xFFD97706); // Amber 600
  static const Color primaryDark = Color(0xFFB45309); // Amber 700
  static const Color primaryLight = Color(0xFFFEF3C7); // Amber 100
  static const Color primarySoft = Color(0xFFFFFBEB); // Amber 50

  // Neutral Backgrounds & Surfaces
  static const Color bgPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100

  // Typography Hierarchy
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1); // Slate 300

  // Semantic Status Colors
  static const Color statusSuccess = Color(0xFF15803D); // Green 700
  static const Color statusSuccessBg = Color(0xFFDCFCE7); // Green 100

  static const Color statusWarning = Color(0xFFB45309); // Amber 700
  static const Color statusWarningBg = Color(0xFFFEF3C7); // Amber 100

  static const Color statusDanger = Color(0xFFB91C1C); // Red 700
  static const Color statusDangerBg = Color(0xFFFEE2E2); // Red 100
}

enum AppLanguage {
  en('en', 'EN', 'English'),
  am('am', 'አማ', 'አማርኛ'),
  om('om', 'OM', 'Afaan Oromoo');

  final String code;
  final String shortBadge;
  final String nativeName;

  const AppLanguage(this.code, this.shortBadge, this.nativeName);

  static AppLanguage fromCode(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final lang in AppLanguage.values) {
      if (lang.code == normalized) return lang;
    }
    return AppLanguage.en;
  }
}

enum UserRole {
  admin('admin'),
  staff('staff');

  final String code;
  const UserRole(this.code);

  static UserRole fromCode(String raw) {
    return raw.trim().toLowerCase() == 'admin'
        ? UserRole.admin
        : UserRole.staff;
  }
}

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
    final clean = raw.trim().toLowerCase();
    for (final cat in MaterialCategory.values) {
      if (cat.code == clean) return cat;
    }
    return MaterialCategory.other;
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
    final clean = raw.trim().toLowerCase();
    switch (clean) {
      case 'pcs':
      case 'piece':
      case 'pieces':
        return MaterialUnit.pcs;
      case 'bars':
      case 'bar':
        return MaterialUnit.bars;
      case 'bags':
      case 'bag':
      case 'sack':
        return MaterialUnit.bags;
      case 'boxes':
      case 'box':
      case 'sqm':
        return MaterialUnit.boxes;
      case 'buckets':
      case 'bucket':
      case 'tin':
        return MaterialUnit.buckets;
      case 'kg':
        return MaterialUnit.kg;
      case 'm':
      case 'meter':
      case 'roll':
        return MaterialUnit.m;
      case 'liters':
      case 'liter':
      case 'l':
        return MaterialUnit.liters;
      default:
        return MaterialUnit.pcs;
    }
  }
}

/// Rounds a double deterministically to 2 decimal places (`BR-005`).
double round2(double value) {
  return (value * 100).roundToDouble() / 100;
}

/// Formats an amount in Ethiopian Birr (`ETB 1,250.00`).
String formatETB(double amount) {
  final fixed = round2(amount).toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final isNeg = intPart.startsWith('-');
  final digits = isNeg ? intPart.substring(1) : intPart;

  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${isNeg ? '-' : ''}ETB ${buffer.toString()}.$decPart';
}

/// Formats stock quantities cleanly (e.g., `240` for whole numbers, `12.5` for decimals).
String formatQty(double qty) {
  final rounded = round2(qty);
  if (rounded == rounded.truncateToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
