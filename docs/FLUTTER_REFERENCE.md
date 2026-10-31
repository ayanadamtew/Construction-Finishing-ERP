# Flutter Android Reference Foundation (`FLUTTER_REFERENCE.md`)

To prevent the AI Studio Node/Bun container from mistaking a `flutter_app/` subdirectory for the root Node.js workspace during `bun install`, the reference Flutter Android (`pubspec.yaml` and `lib/main.dart`) initialization files are documented here alongside `docs/ARCHITECTURE.md`.

## 1. `pubspec.yaml`
```yaml
name: construction_finishing_erp
description: >-
  Mobile-first SKU-free ERP and inventory management system for construction and
  finishing material stores (Rebar, Cement, Tiles, Paint, Hardware) with ETB
  multi-item POS, supplier cost tracking, and physical ground-stock audits.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  http: ^1.2.1
  intl: ^0.19.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.9

flutter:
  uses-material-design: true
```

## 2. `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRouteTab { dashboard, materials, pos, stockIn, auditLog }
enum LanguageCode { en, am, om }

final activeTabProvider = StateProvider<AppRouteTab>((ref) => AppRouteTab.dashboard);
final activeLanguageProvider = StateProvider<LanguageCode>((ref) => LanguageCode.en);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ConstructionErpAndroidApp()));
}

class ConstructionErpAndroidApp extends ConsumerWidget {
  const ConstructionErpAndroidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Construction & Finishing ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F5F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB84A14),
          primary: const Color(0xFFB84A14),
          surface: const Color(0xFFFFFFFF),
          error: const Color(0xFFB91C1C),
        ),
      ),
      home: const ErpAndroidShell(),
    );
  }
}

class ErpAndroidShell extends ConsumerWidget {
  const ErpAndroidShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final language = ref.watch(activeLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Construction & Finishing ERP',
          style: TextStyle(
            color: Color(0xFF14171A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          SegmentedButton<LanguageCode>(
            segments: const [
              ButtonSegment(value: LanguageCode.en, label: Text('EN')),
              ButtonSegment(value: LanguageCode.am, label: Text('አማ')),
              ButtonSegment(value: LanguageCode.om, label: Text('ORO')),
            ],
            selected: {language},
            onSelectionChanged: (selection) {
              ref.read(activeLanguageProvider.notifier).state = selection.first;
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Text(
          'Active Route: ${activeTab.name} (${language.name.toUpperCase()})',
          style: const TextStyle(fontSize: 16, color: Color(0xFF14171A)),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected: (index) {
          ref.read(activeTabProvider.notifier).state = AppRouteTab.values[index];
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Materials'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'POS Sale'),
          NavigationDestination(icon: Icon(Icons.move_to_inbox_outlined), label: 'Stock-In'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Audit & Log'),
        ],
      ),
    );
  }
}
```
