import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show Batch, ConflictAlgorithm, Database;
import 'local/app_database.dart';
import 'tx_store.dart';

typedef _Row = Map<String, Object?>;

/// Backs the local database up to Firestore and restores what is missing.
///
/// Firestore layout:  users/<uid>/transactions | budgets | goals
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _timeout = Duration(seconds: 20);

  bool syncing = false;
  DateTime? lastSync;
  String? lastError;

  /// Returns true when everything synced. Safe to call at any time.
  Future<bool> sync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || syncing) return false;

    syncing = true;
    lastError = null;
    notifyListeners();

    try {
      final uid = user.uid;
      final db = await AppDatabase.instance;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      await _pushAll(db, userDoc, uid);
      await _pullAll(db, userDoc, uid);

      await TxStore.instance.load();
      lastSync = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Sync error: $e');
      lastError = 'Could not sync. Check your internet and try again.';
      return false;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ push

  Future<void> _pushAll(
    Database db,
    DocumentReference<Map<String, dynamic>> userDoc,
    String uid,
  ) async {
    // 1) deletions made on this device
    final deletes = await db.query(
      'pending_deletes',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    for (final r in deletes) {
      final kind = r['kind'] as String;
      final id = r['doc_id'] as String;
      await userDoc.collection(kind).doc(id).delete().timeout(_timeout);
      await db.delete(
        'pending_deletes',
        where: 'uid = ? AND kind = ? AND doc_id = ?',
        whereArgs: [uid, kind, id],
      );
    }

    // 2) new or changed transactions
    await _pushRows(
      db: db,
      col: userDoc.collection('transactions'),
      rows: await db.query(
        'money_tx',
        where: 'uid = ? AND synced = 0',
        whereArgs: [uid],
      ),
      docId: (r) => r['id'] as String,
      data: (r) => {
        for (final e in r.entries)
          if (e.key != 'synced') e.key: e.value,
      },
      markSynced: (b, r) => b.update(
        'money_tx',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [r['id']],
      ),
    );

    // 3) new or changed goals
    await _pushRows(
      db: db,
      col: userDoc.collection('goals'),
      rows: await db.query(
        'goals',
        where: 'uid = ? AND synced = 0',
        whereArgs: [uid],
      ),
      docId: (r) => r['id'] as String,
      data: (r) => {
        for (final e in r.entries)
          if (e.key != 'synced') e.key: e.value,
      },
      markSynced: (b, r) => b.update(
        'goals',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [r['id']],
      ),
    );

    // 4) new or changed budgets (the category name is the document id)
    await _pushRows(
      db: db,
      col: userDoc.collection('budgets'),
      rows: await db.query(
        'budgets',
        where: 'uid = ? AND synced = 0',
        whereArgs: [uid],
      ),
      docId: (r) => r['category'] as String,
      data: (r) => {'category': r['category'], 'limit_cents': r['limit_cents']},
      markSynced: (b, r) => b.update(
        'budgets',
        {'synced': 1},
        where: 'uid = ? AND category = ?',
        whereArgs: [uid, r['category']],
      ),
    );
  }

  Future<void> _pushRows({
    required Database db,
    required CollectionReference<Map<String, dynamic>> col,
    required List<_Row> rows,
    required String Function(_Row) docId,
    required Map<String, dynamic> Function(_Row) data,
    required void Function(Batch, _Row) markSynced,
  }) async {
    // Firestore allows at most 500 writes per batch.
    for (var i = 0; i < rows.length; i += 400) {
      final chunk = rows.sublist(i, math.min(i + 400, rows.length));

      final writes = FirebaseFirestore.instance.batch();
      for (final r in chunk) {
        writes.set(col.doc(docId(r)), data(r));
      }
      await writes.commit().timeout(_timeout);

      final local = db.batch();
      for (final r in chunk) {
        markSynced(local, r);
      }
      await local.commit(noResult: true);
    }
  }

  // ------------------------------------------------------------------ pull
  // Only adds what is missing on this device. Items you already have are
  // never overwritten.

  Future<void> _pullAll(
    Database db,
    DocumentReference<Map<String, dynamic>> userDoc,
    String uid,
  ) async {
    const fromServer = GetOptions(source: Source.server);

    // transactions
    final txSnap = await userDoc
        .collection('transactions')
        .get(fromServer)
        .timeout(_timeout);
    final haveTx = await _localIds(db, 'money_tx', 'id', uid);
    final txBatch = db.batch();
    for (final d in txSnap.docs) {
      if (haveTx.contains(d.id)) continue;
      final m = d.data();
      txBatch.insert('money_tx', {
        'id': d.id,
        'uid': uid,
        'type': m['type'] ?? 'expense',
        'amount_cents': _int(m['amount_cents']),
        'category': m['category'] ?? 'Other',
        'note': m['note'] ?? '',
        'date': m['date'] ?? '',
        'created_at': _int(m['created_at']),
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await txBatch.commit(noResult: true);

    // goals
    final goalSnap = await userDoc
        .collection('goals')
        .get(fromServer)
        .timeout(_timeout);
    final haveGoals = await _localIds(db, 'goals', 'id', uid);
    final goalBatch = db.batch();
    for (final d in goalSnap.docs) {
      if (haveGoals.contains(d.id)) continue;
      final m = d.data();
      goalBatch.insert('goals', {
        'id': d.id,
        'uid': uid,
        'name': m['name'] ?? 'Goal',
        'icon': m['icon'] ?? '🎯',
        'target_cents': _int(m['target_cents']),
        'saved_cents': _int(m['saved_cents']),
        'due': m['due'] ?? '',
        'created_at': _int(m['created_at']),
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await goalBatch.commit(noResult: true);

    // budgets
    final budgetSnap = await userDoc
        .collection('budgets')
        .get(fromServer)
        .timeout(_timeout);
    final haveBudgets = await _localIds(db, 'budgets', 'category', uid);
    final budgetBatch = db.batch();
    for (final d in budgetSnap.docs) {
      if (haveBudgets.contains(d.id)) continue;
      final m = d.data();
      budgetBatch.insert('budgets', {
        'uid': uid,
        'category': d.id,
        'limit_cents': _int(m['limit_cents']),
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await budgetBatch.commit(noResult: true);
  }

  Future<Set<String>> _localIds(
    Database db,
    String table,
    String column,
    String uid,
  ) async {
    final rows = await db.query(
      table,
      columns: [column],
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return rows.map((r) => r[column] as String).toSet();
  }

  int _int(Object? v) => (v as num?)?.toInt() ?? 0;
}
