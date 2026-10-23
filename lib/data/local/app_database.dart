import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Local SQLite database (works offline). On Chrome it uses a web build.
class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async => _db ??= await _open();

  static Future<Database> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'clearcash.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTransactions(db);
        await _createBudgets(db);
        await _createGoals(db);
        await _createPendingDeletes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Existing installs keep their data and only get what is new.
        if (oldVersion < 2) {
          await _createBudgets(db);
        } else if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await _createGoals(db);
        } else if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE goals ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await _createPendingDeletes(db);
        }
      },
    );
  }

  static Future<void> _createTransactions(Database db) async {
    await db.execute('''
      CREATE TABLE money_tx (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_tx_uid_date ON money_tx (uid, date)');
  }

  static Future<void> _createBudgets(Database db) async {
    await db.execute('''
      CREATE TABLE budgets (
        uid TEXT NOT NULL,
        category TEXT NOT NULL,
        limit_cents INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (uid, category)
      )
    ''');
  }

  static Future<void> _createGoals(Database db) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        target_cents INTEGER NOT NULL,
        saved_cents INTEGER NOT NULL DEFAULT 0,
        due TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Things deleted on this device that Firestore has not been told about yet.
  static Future<void> _createPendingDeletes(Database db) async {
    await db.execute('''
      CREATE TABLE pending_deletes (
        uid TEXT NOT NULL,
        kind TEXT NOT NULL,
        doc_id TEXT NOT NULL,
        PRIMARY KEY (uid, kind, doc_id)
      )
    ''');
  }
}
