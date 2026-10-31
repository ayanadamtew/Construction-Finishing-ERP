# Construction & Finishing Material Store Mobile ERP (Flutter Android)

This directory contains the native **Flutter Android (`Dart 3`)** application for the **Construction & Finishing Material Store Mobile ERP & Inventory Management System**, engineered in compliance with:

- `docs/PRODUCT_BRIEF.md`
- `docs/SRS.md`
- `docs/ARCHITECTURE.md` (Section 14.2)
- `docs/DATABASE_DESIGN.md` (Section 4 SQLite DDL)
- `docs/API_CONTRACT.md`
- `docs/UI_UX_SPEC.md`

---

## Key Capabilities

1. **SKU-Free Material Registration (`FR-001`–`FR-005`):** Register construction and finishing materials (`rebar`, `cement`, `tiles`, `paint`, `hardware`, `other`) by descriptive name, specs, single tracking unit (`pcs`, `bars`, `bags`, `boxes`, `buckets`, `kg`, `m`, `liters`), stock thresholds, and `ETB` prices—with zero barcode or SKU complexity.
2. **Multi-Item POS Sales & Stock-Floor Guard (`FR-006`–`FR-011`, `BR-002`):** Add multiple materials to a single sale receipt, automatically merge duplicate material lines (`BR-003`), preview remaining stock and profit in real time, and strictly block any sale that would push stock below `0`.
3. **Supplier Stock-In & Weighted-Average Costing (`FR-012`–`FR-015`, `BR-006`):** Record incoming deliveries and recalculate weighted-average unit cost in **Ethiopian Birr (`ETB`)** to `2` decimal places.
4. **Physical Ground-Stock Audit & Reconciliation (`FR-016`–`FR-019`):** Enter physical ground counts, inspect live +/- variance and `ETB` value impact, and atomically reconcile system stock.
5. **Trilingual Runtime Localization (`FR-022`, `NFR-001`):** Instant header switcher between **English (`EN`)**, **Amharic (`አማ`)**, and **Afan Oromo (`OM`)** without losing unsaved POS cart items or audit inputs (`FAIL-003`).
6. **Offline-First SQLite + Optional Express REST API Sync (`NFR-005`):** Uses local `sqflite` ACID transactions matching `docs/DATABASE_DESIGN.md` Section 4 and optionally synchronizes with the Express `/api/*` server.

---

## Directory Structure

```text
flutter_android/
├── pubspec.yaml
├── analysis_options.yaml
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/com/construction/erp/MainActivity.kt
├── lib/
│   ├── main.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_am.arb
│   │   ├── app_om.arb
│   │   └── erp_localizations.dart
│   ├── core/
│   │   ├── constants/erp_constants.dart
│   │   └── errors/domain_error.dart
│   ├── domain/
│   │   ├── models/erp_models.dart
│   │   └── services/inventory_engine.dart
│   ├── data/
│   │   ├── local/sqlite_database.dart
│   │   ├── remote/erp_api_client.dart
│   │   └── repositories/erp_repository.dart
│   └── presentation/
│       ├── providers/erp_providers.dart
│       └── screens/
│           ├── dashboard_screen.dart
│           ├── materials_screen.dart
│           ├── sales_pos_screen.dart
│           ├── stock_in_screen.dart
│           ├── stock_audit_screen.dart
│           └── history_screen.dart
└── test/
    └── inventory_engine_test.dart
```

---

## Building & Running on Android

```bash
cd flutter_android
flutter pub get
flutter test
flutter run
# Or build release APK:
flutter build apk --release
```
