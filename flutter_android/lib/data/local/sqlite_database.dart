import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/erp_constants.dart';
import '../../domain/models/erp_models.dart';
import '../../domain/services/auth_engine.dart';
import '../../domain/services/inventory_engine.dart';

/// Native Android SQLite persistence helper (`Sqflite`) implementing the exact
/// schema and indexes defined in `docs/DATABASE_DESIGN.md` Section 4 (v3 with Production Cleanup, Auth, Categories, Archive & Reversals).
class SqliteDatabaseHelper {
  static const String _dbName = 'senay_construction_erp.db';
  static const int _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        // Production database starts clean with 0 sample materials or transactions.
        final initial = InventoryEngine.createProductionState();
        await _persistFullStateInTransaction(db, initial);
        await _ensureDefaultAdminSeeded(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateV2ToV3(db);
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
        password_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY NOT NULL,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        created_by TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS materials (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 120),
        category TEXT NOT NULL,
        specs TEXT NOT NULL DEFAULT '' CHECK (length(specs) <= 120),
        unit TEXT NOT NULL CHECK (unit IN ('pcs', 'bars', 'bags', 'boxes', 'buckets', 'kg', 'm', 'liters')),
        current_stock REAL NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
        min_stock_level REAL NOT NULL DEFAULT 0 CHECK (min_stock_level >= 0),
        unit_cost REAL NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
        default_selling_price REAL NOT NULL DEFAULT 0 CHECK (default_selling_price >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        archived_at TEXT,
        archived_by TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_materials_category ON materials(category);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_materials_name ON materials(name COLLATE NOCASE);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_materials_low_stock ON materials(current_stock, min_stock_level);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_transactions (
        id TEXT PRIMARY KEY NOT NULL,
        total_amount REAL NOT NULL CHECK (total_amount >= 0),
        total_cost REAL NOT NULL CHECK (total_cost >= 0),
        total_profit REAL NOT NULL,
        customer_note TEXT NOT NULL DEFAULT '' CHECK (length(customer_note) <= 200),
        created_at TEXT NOT NULL,
        is_reversed INTEGER NOT NULL DEFAULT 0,
        reversed_at TEXT,
        reversed_by TEXT,
        reversal_reason TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sale_transactions(created_at DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_line_items (
        id TEXT PRIMARY KEY NOT NULL,
        sale_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL CHECK (quantity > 0),
        unit_selling_price REAL NOT NULL CHECK (unit_selling_price >= 0),
        unit_cost_snapshot REAL NOT NULL CHECK (unit_cost_snapshot >= 0),
        line_total REAL NOT NULL CHECK (line_total >= 0),
        line_profit REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sale_transactions(id) ON DELETE CASCADE,
        FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_lines_sale_id ON sale_line_items(sale_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_lines_material_id ON sale_line_items(material_id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_in_records (
        id TEXT PRIMARY KEY NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity_added REAL NOT NULL CHECK (quantity_added > 0),
        unit_purchase_cost REAL NOT NULL CHECK (unit_purchase_cost >= 0),
        total_purchase_cost REAL NOT NULL CHECK (total_purchase_cost >= 0),
        previous_stock REAL NOT NULL CHECK (previous_stock >= 0),
        new_stock REAL NOT NULL CHECK (new_stock >= 0),
        previous_unit_cost REAL NOT NULL CHECK (previous_unit_cost >= 0),
        new_unit_cost REAL NOT NULL CHECK (new_unit_cost >= 0),
        supplier_note TEXT NOT NULL DEFAULT '' CHECK (length(supplier_note) <= 200),
        created_at TEXT NOT NULL,
        is_reversed INTEGER NOT NULL DEFAULT 0,
        reversed_at TEXT,
        reversed_by TEXT,
        reversal_reason TEXT,
        FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_in_created_at ON stock_in_records(created_at DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_in_material_id ON stock_in_records(material_id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_audit_records (
        id TEXT PRIMARY KEY NOT NULL,
        audit_note TEXT NOT NULL DEFAULT '' CHECK (length(audit_note) <= 200),
        created_at TEXT NOT NULL,
        is_reversed INTEGER NOT NULL DEFAULT 0,
        reversed_at TEXT,
        reversed_by TEXT,
        reversal_reason TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_audit_created_at ON stock_audit_records(created_at DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_line_items (
        id TEXT PRIMARY KEY NOT NULL,
        audit_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        expected_stock REAL NOT NULL CHECK (expected_stock >= 0),
        physical_count REAL NOT NULL CHECK (physical_count >= 0),
        variance REAL NOT NULL,
        unit_cost_snapshot REAL NOT NULL CHECK (unit_cost_snapshot >= 0),
        FOREIGN KEY (audit_id) REFERENCES stock_audit_records(id) ON DELETE CASCADE,
        FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_lines_audit_id ON audit_line_items(audit_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_lines_material_id ON audit_line_items(material_id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sample_data_backups (
        id TEXT PRIMARY KEY NOT NULL,
        entity_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        backed_up_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'staff')),
        password_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY NOT NULL,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        created_by TEXT
      );
    ''');

    final List<String> alterStatements = <String>[
      'ALTER TABLE materials ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE materials ADD COLUMN archived_at TEXT;',
      'ALTER TABLE materials ADD COLUMN archived_by TEXT;',
      'ALTER TABLE sale_transactions ADD COLUMN is_reversed INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE sale_transactions ADD COLUMN reversed_at TEXT;',
      'ALTER TABLE sale_transactions ADD COLUMN reversed_by TEXT;',
      'ALTER TABLE sale_transactions ADD COLUMN reversal_reason TEXT;',
      'ALTER TABLE stock_in_records ADD COLUMN is_reversed INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE stock_in_records ADD COLUMN reversed_at TEXT;',
      'ALTER TABLE stock_in_records ADD COLUMN reversed_by TEXT;',
      'ALTER TABLE stock_in_records ADD COLUMN reversal_reason TEXT;',
      'ALTER TABLE stock_audit_records ADD COLUMN is_reversed INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE stock_audit_records ADD COLUMN reversed_at TEXT;',
      'ALTER TABLE stock_audit_records ADD COLUMN reversed_by TEXT;',
      'ALTER TABLE stock_audit_records ADD COLUMN reversal_reason TEXT;',
    ];

    for (final stmt in alterStatements) {
      try {
        await db.execute(stmt);
      } catch (_) {
        // Ignore if column already exists
      }
    }

    await _ensureDefaultAdminSeeded(db);
    final existingCats = await db.query('categories');
    if (existingCats.isEmpty) {
      for (final cat in InventoryEngine.createDefaultCategories()) {
        await db.insert(
          'categories',
          {
            'id': cat.id,
            'code': cat.code,
            'name': cat.name,
            'is_system': cat.isSystem ? 1 : 0,
            'created_at': cat.createdAt,
            'created_by': cat.createdBy,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _migrateV2ToV3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sample_data_backups (
        id TEXT PRIMARY KEY NOT NULL,
        entity_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        backed_up_at TEXT NOT NULL
      );
    ''');

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final salesRows = await db.query('sale_transactions');
    final saleLinesRows = await db.query('sale_line_items');
    final stockInRows = await db.query('stock_in_records');
    final auditLineRows = await db.query('audit_line_items');
    final materialRows = await db.query('materials');

    // Identify materials referenced by ANY genuine (non-sample) transaction
    final genuineMaterialIds = <String>{};
    for (final s in salesRows) {
      final saleId = s['id'] as String;
      if (!InventoryEngine.knownSampleSaleIds.contains(saleId)) {
        for (final line in saleLinesRows.where((l) => l['sale_id'] == saleId)) {
          genuineMaterialIds.add(line['material_id'] as String);
        }
      }
    }
    for (final stin in stockInRows) {
      final stinId = stin['id'] as String;
      if (!InventoryEngine.knownSampleStockInIds.contains(stinId)) {
        genuineMaterialIds.add(stin['material_id'] as String);
      }
    }
    for (final al in auditLineRows) {
      genuineMaterialIds.add(al['material_id'] as String);
    }

    await db.transaction((txn) async {
      // 1. Back up and remove sample sale transactions
      for (final sale in salesRows) {
        final saleId = sale['id'] as String;
        if (InventoryEngine.knownSampleSaleIds.contains(saleId)) {
          final lines =
              saleLinesRows.where((l) => l['sale_id'] == saleId).toList();
          await txn.insert(
            'sample_data_backups',
            {
              'id': 'sale_$saleId',
              'entity_type': 'sale_transaction',
              'payload_json': jsonEncode({'sale': sale, 'items': lines}),
              'backed_up_at': nowIso,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(
            'sale_line_items',
            where: 'sale_id = ?',
            whereArgs: [saleId],
          );
          await txn.delete(
            'sale_transactions',
            where: 'id = ?',
            whereArgs: [saleId],
          );
        }
      }

      // 2. Back up and remove sample stock-in records
      for (final stin in stockInRows) {
        final stinId = stin['id'] as String;
        if (InventoryEngine.knownSampleStockInIds.contains(stinId)) {
          await txn.insert(
            'sample_data_backups',
            {
              'id': 'stockin_$stinId',
              'entity_type': 'stock_in_record',
              'payload_json': jsonEncode(stin),
              'backed_up_at': nowIso,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(
            'stock_in_records',
            where: 'id = ?',
            whereArgs: [stinId],
          );
        }
      }

      // 3. Back up and remove sample materials ONLY if not referenced by genuine transactions
      for (final mat in materialRows) {
        final matId = mat['id'] as String;
        if (InventoryEngine.knownSampleMaterialIds.contains(matId) &&
            !genuineMaterialIds.contains(matId)) {
          await txn.insert(
            'sample_data_backups',
            {
              'id': 'material_$matId',
              'entity_type': 'material',
              'payload_json': jsonEncode(mat),
              'backed_up_at': nowIso,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.delete(
            'materials',
            where: 'id = ?',
            whereArgs: [matId],
          );
        }
      }
    });
  }

  Future<void> _ensureDefaultAdminSeeded(Database db) async {
    final userRows = await db.query('users');
    if (userRows.isEmpty) {
      final defaultAdmin = AuthEngine.createDefaultAdminUser();
      await db.insert(
        'users',
        {
          'id': defaultAdmin.id,
          'username': defaultAdmin.username,
          'email': defaultAdmin.email,
          'full_name': defaultAdmin.fullName,
          'role': defaultAdmin.role.code,
          'password_hash': defaultAdmin.passwordHash,
          'is_active': defaultAdmin.isActive ? 1 : 0,
          'created_at': defaultAdmin.createdAt,
          'last_login_at': defaultAdmin.lastLoginAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<UserAccount>> loadUsers() async {
    final db = await database;
    await _ensureDefaultAdminSeeded(db);
    final rows = await db.query('users', orderBy: 'created_at ASC');
    return rows
        .map(
          (row) => UserAccount(
            id: row['id'] as String,
            username: row['username'] as String,
            email: row['email'] as String,
            fullName: row['full_name'] as String,
            role: UserRole.fromCode(row['role'] as String),
            passwordHash: row['password_hash'] as String,
            isActive: ((row['is_active'] as num?) ?? 1) != 0,
            createdAt: row['created_at'] as String,
            lastLoginAt: row['last_login_at'] as String?,
          ),
        )
        .toList();
  }

  Future<void> saveUsers(List<UserAccount> users) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('users');
      for (final u in users) {
        await txn.insert('users', {
          'id': u.id,
          'username': u.username,
          'email': u.email,
          'full_name': u.fullName,
          'role': u.role.code,
          'password_hash': u.passwordHash,
          'is_active': u.isActive ? 1 : 0,
          'created_at': u.createdAt,
          'last_login_at': u.lastLoginAt,
        });
      }
    });
  }

  Future<UserAccount?> loadActiveSessionUser(List<UserAccount> users) async {
    final db = await database;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await db.query('sessions', orderBy: 'created_at DESC', limit: 1);
    if (rows.isEmpty) return null;

    final session = rows.first;
    final expiresAt = (session['expires_at'] as String?) ?? '';
    if (expiresAt.compareTo(nowIso) <= 0) {
      await db.delete('sessions');
      return null;
    }

    final userId = session['user_id'] as String;
    for (final u in users) {
      if (u.id == userId && u.isActive) {
        return u;
      }
    }
    return null;
  }

  Future<String> createSession(String userId) async {
    final db = await database;
    final now = DateTime.now().toUtc();
    final expires = now.add(const Duration(hours: 12));
    final token = AuthEngine.generateRandomHex(24);
    await db.transaction((txn) async {
      await txn.delete('sessions');
      await txn.insert('sessions', {
        'id': token,
        'user_id': userId,
        'created_at': now.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
    });
    return token;
  }

  Future<void> clearSessions() async {
    final db = await database;
    await db.delete('sessions');
  }

  Future<ErpState> loadState() async {
    final db = await database;

    final catRows = await db.query('categories', orderBy: 'created_at ASC');
    final categories = catRows.isNotEmpty
        ? catRows
            .map(
              (row) => CategoryRecord(
                id: row['id'] as String,
                code: row['code'] as String,
                name: row['name'] as String,
                isSystem: ((row['is_system'] as num?) ?? 0) != 0,
                createdAt: row['created_at'] as String,
                createdBy: row['created_by'] as String?,
              ),
            )
            .toList()
        : InventoryEngine.createDefaultCategories();

    final matRows = await db.query('materials', orderBy: 'created_at DESC');
    final materials = matRows
        .map(
          (row) => MaterialItem(
            id: row['id'] as String,
            name: row['name'] as String,
            category: MaterialCategory.fromCode(row['category'] as String),
            categoryCode: row['category'] as String,
            specs: (row['specs'] as String?) ?? '',
            unit: MaterialUnit.fromCode(row['unit'] as String),
            currentStock: (row['current_stock'] as num).toDouble(),
            minStockLevel: (row['min_stock_level'] as num).toDouble(),
            unitCost: (row['unit_cost'] as num).toDouble(),
            defaultSellingPrice:
                (row['default_selling_price'] as num).toDouble(),
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String,
            isArchived: ((row['is_archived'] as num?) ?? 0) != 0,
            archivedAt: row['archived_at'] as String?,
            archivedBy: row['archived_by'] as String?,
          ),
        )
        .toList();

    final saleRows =
        await db.query('sale_transactions', orderBy: 'created_at DESC');
    final saleLineRows = await db.query('sale_line_items');

    final Map<String, List<SaleLineItem>> linesBySaleId = {};
    for (final row in saleLineRows) {
      final saleId = row['sale_id'] as String;
      linesBySaleId.putIfAbsent(saleId, () => []).add(
            SaleLineItem(
              id: row['id'] as String,
              materialId: row['material_id'] as String,
              materialName: row['material_name'] as String,
              unit: MaterialUnit.fromCode(row['unit'] as String),
              quantity: (row['quantity'] as num).toDouble(),
              unitSellingPrice: (row['unit_selling_price'] as num).toDouble(),
              unitCostSnapshot: (row['unit_cost_snapshot'] as num).toDouble(),
              lineTotal: (row['line_total'] as num).toDouble(),
              lineProfit: (row['line_profit'] as num).toDouble(),
            ),
          );
    }

    final sales = saleRows
        .map(
          (row) => SaleTransaction(
            id: row['id'] as String,
            items: linesBySaleId[row['id'] as String] ?? const [],
            totalAmount: (row['total_amount'] as num).toDouble(),
            totalCost: (row['total_cost'] as num).toDouble(),
            totalProfit: (row['total_profit'] as num).toDouble(),
            customerNote: (row['customer_note'] as String?) ?? '',
            createdAt: row['created_at'] as String,
            isReversed: ((row['is_reversed'] as num?) ?? 0) != 0,
            reversedAt: row['reversed_at'] as String?,
            reversedBy: row['reversed_by'] as String?,
            reversalReason: row['reversal_reason'] as String?,
          ),
        )
        .toList();

    final stockInRows =
        await db.query('stock_in_records', orderBy: 'created_at DESC');
    final stockIns = stockInRows
        .map(
          (row) => StockInRecord(
            id: row['id'] as String,
            materialId: row['material_id'] as String,
            materialName: row['material_name'] as String,
            unit: MaterialUnit.fromCode(row['unit'] as String),
            quantityAdded: (row['quantity_added'] as num).toDouble(),
            unitPurchaseCost: (row['unit_purchase_cost'] as num).toDouble(),
            totalPurchaseCost: (row['total_purchase_cost'] as num).toDouble(),
            previousStock: (row['previous_stock'] as num).toDouble(),
            newStock: (row['new_stock'] as num).toDouble(),
            previousUnitCost: (row['previous_unit_cost'] as num).toDouble(),
            newUnitCost: (row['new_unit_cost'] as num).toDouble(),
            supplierNote: (row['supplier_note'] as String?) ?? '',
            createdAt: row['created_at'] as String,
            isReversed: ((row['is_reversed'] as num?) ?? 0) != 0,
            reversedAt: row['reversed_at'] as String?,
            reversedBy: row['reversed_by'] as String?,
            reversalReason: row['reversal_reason'] as String?,
          ),
        )
        .toList();

    final auditRows =
        await db.query('stock_audit_records', orderBy: 'created_at DESC');
    final auditLineRows = await db.query('audit_line_items');

    final Map<String, List<AuditLineItem>> linesByAuditId = {};
    for (final row in auditLineRows) {
      final auditId = row['audit_id'] as String;
      linesByAuditId.putIfAbsent(auditId, () => []).add(
            AuditLineItem(
              materialId: row['material_id'] as String,
              materialName: row['material_name'] as String,
              unit: MaterialUnit.fromCode(row['unit'] as String),
              expectedStock: (row['expected_stock'] as num).toDouble(),
              physicalCount: (row['physical_count'] as num).toDouble(),
              variance: (row['variance'] as num).toDouble(),
              unitCostSnapshot: (row['unit_cost_snapshot'] as num).toDouble(),
            ),
          );
    }

    final audits = auditRows
        .map(
          (row) => StockAuditRecord(
            id: row['id'] as String,
            adjustments: linesByAuditId[row['id'] as String] ?? const [],
            auditNote: (row['audit_note'] as String?) ?? '',
            createdAt: row['created_at'] as String,
            isReversed: ((row['is_reversed'] as num?) ?? 0) != 0,
            reversedAt: row['reversed_at'] as String?,
            reversedBy: row['reversed_by'] as String?,
            reversalReason: row['reversal_reason'] as String?,
          ),
        )
        .toList();

    return ErpState(
      materials: materials,
      sales: sales,
      stockIns: stockIns,
      audits: audits,
      categories: categories,
      summary: InventoryEngine.calculateSummary(
        materials: materials,
        sales: sales,
      ),
    );
  }

  Future<void> saveState(ErpState state) async {
    final db = await database;
    await _persistFullStateInTransaction(db, state);
  }

  Future<void> _persistFullStateInTransaction(
    Database db,
    ErpState state,
  ) async {
    await db.transaction((txn) async {
      await txn.delete('sale_line_items');
      await txn.delete('sale_transactions');
      await txn.delete('stock_in_records');
      await txn.delete('audit_line_items');
      await txn.delete('stock_audit_records');
      await txn.delete('materials');
      await txn.delete('categories');

      final categories = state.categories.isNotEmpty
          ? state.categories
          : InventoryEngine.createDefaultCategories();
      for (final c in categories) {
        await txn.insert('categories', {
          'id': c.id,
          'code': c.code,
          'name': c.name,
          'is_system': c.isSystem ? 1 : 0,
          'created_at': c.createdAt,
          'created_by': c.createdBy,
        });
      }

      for (final m in state.materials) {
        await txn.insert('materials', {
          'id': m.id,
          'name': m.name,
          'category': m.effectiveCategoryCode,
          'specs': m.specs,
          'unit': m.unit.code,
          'current_stock': m.currentStock,
          'min_stock_level': m.minStockLevel,
          'unit_cost': m.unitCost,
          'default_selling_price': m.defaultSellingPrice,
          'created_at': m.createdAt,
          'updated_at': m.updatedAt,
          'is_archived': m.isArchived ? 1 : 0,
          'archived_at': m.archivedAt,
          'archived_by': m.archivedBy,
        });
      }

      for (final sale in state.sales) {
        await txn.insert('sale_transactions', {
          'id': sale.id,
          'total_amount': sale.totalAmount,
          'total_cost': sale.totalCost,
          'total_profit': sale.totalProfit,
          'customer_note': sale.customerNote,
          'created_at': sale.createdAt,
          'is_reversed': sale.isReversed ? 1 : 0,
          'reversed_at': sale.reversedAt,
          'reversed_by': sale.reversedBy,
          'reversal_reason': sale.reversalReason,
        });
        for (final line in sale.items) {
          await txn.insert('sale_line_items', {
            'id': line.id,
            'sale_id': sale.id,
            'material_id': line.materialId,
            'material_name': line.materialName,
            'unit': line.unit.code,
            'quantity': line.quantity,
            'unit_selling_price': line.unitSellingPrice,
            'unit_cost_snapshot': line.unitCostSnapshot,
            'line_total': line.lineTotal,
            'line_profit': line.lineProfit,
          });
        }
      }

      for (final stin in state.stockIns) {
        await txn.insert('stock_in_records', {
          'id': stin.id,
          'material_id': stin.materialId,
          'material_name': stin.materialName,
          'unit': stin.unit.code,
          'quantity_added': stin.quantityAdded,
          'unit_purchase_cost': stin.unitPurchaseCost,
          'total_purchase_cost': stin.totalPurchaseCost,
          'previous_stock': stin.previousStock,
          'new_stock': stin.newStock,
          'previous_unit_cost': stin.previousUnitCost,
          'new_unit_cost': stin.newUnitCost,
          'supplier_note': stin.supplierNote,
          'created_at': stin.createdAt,
          'is_reversed': stin.isReversed ? 1 : 0,
          'reversed_at': stin.reversedAt,
          'reversed_by': stin.reversedBy,
          'reversal_reason': stin.reversalReason,
        });
      }

      for (final aud in state.audits) {
        await txn.insert('stock_audit_records', {
          'id': aud.id,
          'audit_note': aud.auditNote,
          'created_at': aud.createdAt,
          'is_reversed': aud.isReversed ? 1 : 0,
          'reversed_at': aud.reversedAt,
          'reversed_by': aud.reversedBy,
          'reversal_reason': aud.reversalReason,
        });
        for (int i = 0; i < aud.adjustments.length; i++) {
          final adj = aud.adjustments[i];
          await txn.insert('audit_line_items', {
            'id': '${aud.id}-line-$i',
            'audit_id': aud.id,
            'material_id': adj.materialId,
            'material_name': adj.materialName,
            'unit': adj.unit.code,
            'expected_stock': adj.expectedStock,
            'physical_count': adj.physicalCount,
            'variance': adj.variance,
            'unit_cost_snapshot': adj.unitCostSnapshot,
          });
        }
      }
    });
  }
}
