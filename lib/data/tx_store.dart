import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'local/app_database.dart';
import 'models/goal.dart';
import 'models/money_tx.dart';

/// Holds the signed-in user's transactions, budgets and goals, plus the
/// totals shown on screens. Every change is marked "not synced" so the
/// sync service knows what to upload.
class TxStore extends ChangeNotifier {
  TxStore._();
  static final TxStore instance = TxStore._();

  List<MoneyTx> _items = const [];
  List<MoneyTx> get items => _items;

  /// Monthly limit per category, in centavos.
  Map<String, int> _budgets = const {};
  Map<String, int> get budgets => _budgets;

  List<Goal> _goals = const [];
  List<Goal> get goals => _goals;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void clear() {
    _items = const [];
    _budgets = const {};
    _goals = const [];
  }

  Future<void> load() async {
    final db = await AppDatabase.instance;

    final rows = await db.query(
      'money_tx',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC, created_at DESC',
    );
    _items = rows.map(MoneyTx.fromMap).toList();

    final budgetRows = await db.query(
      'budgets',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    _budgets = {
      for (final r in budgetRows)
        r['category'] as String: r['limit_cents'] as int,
    };

    final goalRows = await db.query(
      'goals',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at ASC',
    );
    _goals = goalRows.map(Goal.fromMap).toList();

    notifyListeners();
  }

  /// Remembers that something was deleted here, so Firestore gets told later.
  Future<void> _rememberDelete(String kind, String docId) async {
    final db = await AppDatabase.instance;
    await db.insert('pending_deletes', {
      'uid': uid,
      'kind': kind,
      'doc_id': docId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Forgets a remembered delete (used when the same item is created again).
  Future<void> _forgetDelete(String kind, String docId) async {
    final db = await AppDatabase.instance;
    await db.delete(
      'pending_deletes',
      where: 'uid = ? AND kind = ? AND doc_id = ?',
      whereArgs: [uid, kind, docId],
    );
  }

  // ---- transactions ----

  Future<void> save(MoneyTx t) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'money_tx',
      t.toMap(), // synced = 0 (needs upload)
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await load();
  }

  Future<void> remove(String id) async {
    final db = await AppDatabase.instance;
    await db.delete('money_tx', where: 'id = ?', whereArgs: [id]);
    await _rememberDelete('transactions', id);
    await load();
  }

  // ---- goals ----

  Future<void> saveGoal(Goal g) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'goals',
      g.toMap(), // synced defaults to 0
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await load();
  }

  Future<void> removeGoal(String id) async {
    final db = await AppDatabase.instance;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
    await _rememberDelete('goals', id);
    await load();
  }

  /// Adds money to a goal. Pass a negative number to take money back out.
  Future<void> addToGoal(String id, int deltaCents) async {
    final goal = _goals.where((g) => g.id == id).firstOrNull;
    if (goal == null) return;
    final next = goal.savedCents + deltaCents;
    final db = await AppDatabase.instance;
    await db.update(
      'goals',
      {'saved_cents': next < 0 ? 0 : next, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await load();
  }

  int get totalSavedCents => _goals.fold(0, (a, g) => a + g.savedCents);
  int get totalGoalTargetCents => _goals.fold(0, (a, g) => a + g.targetCents);

  // ---- budgets ----

  /// Sets (or changes) a category's monthly limit. A limit of 0 removes it.
  Future<void> setBudget(String category, int limitCents) async {
    final db = await AppDatabase.instance;
    if (limitCents <= 0) {
      await db.delete(
        'budgets',
        where: 'uid = ? AND category = ?',
        whereArgs: [uid, category],
      );
      await _rememberDelete('budgets', category);
    } else {
      await db.insert('budgets', {
        'uid': uid,
        'category': category,
        'limit_cents': limitCents,
        'synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _forgetDelete('budgets', category);
    }
    await load();
  }

  int spentThisMonth(String category) => _items
      .where((t) => !t.isIncome && t.category == category && _thisMonth(t.date))
      .fold(0, (s, t) => s + t.cents);

  /// Every budgeted category with its spending, fullest first.
  List<BudgetStatus> budgetStatuses() {
    final list = _budgets.entries
        .map((e) => BudgetStatus(e.key, e.value, spentThisMonth(e.key)))
        .toList();
    list.sort((a, b) => b.percent.compareTo(a.percent));
    return list;
  }

  int get totalBudgetCents => _budgets.values.fold(0, (a, b) => a + b);

  /// Spending only inside budgeted categories (this month).
  int get totalBudgetSpentCents =>
      _budgets.keys.fold(0, (a, c) => a + spentThisMonth(c));

  // ---- totals (all in centavos) ----

  int get balanceCents =>
      _items.fold(0, (s, t) => s + (t.isIncome ? t.cents : -t.cents));

  bool _thisMonth(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month;
  }

  int get monthIncomeCents => _items
      .where((t) => t.isIncome && _thisMonth(t.date))
      .fold(0, (s, t) => s + t.cents);

  int get monthExpenseCents => _items
      .where((t) => !t.isIncome && _thisMonth(t.date))
      .fold(0, (s, t) => s + t.cents);

  int get weekExpenseCents {
    final n = DateTime.now();
    final start = DateTime(
      n.year,
      n.month,
      n.day,
    ).subtract(const Duration(days: 6));
    return _items
        .where((t) => !t.isIncome && !t.date.isBefore(start))
        .fold(0, (s, t) => s + t.cents);
  }

  /// Income and expense totals for each of the last 6 months (oldest first).
  List<MonthTotals> lastSixMonths() {
    final now = DateTime.now();
    final result = <MonthTotals>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      var income = 0;
      var expense = 0;
      for (final t in _items) {
        if (t.date.year == m.year && t.date.month == m.month) {
          if (t.isIncome) {
            income += t.cents;
          } else {
            expense += t.cents;
          }
        }
      }
      result.add(MonthTotals(m, income, expense));
    }
    return result;
  }

  /// This month's expenses per category, biggest first.
  List<CategoryTotal> expenseByCategoryThisMonth() {
    final map = <String, int>{};
    for (final t in _items) {
      if (!t.isIncome && _thisMonth(t.date)) {
        map[t.category] = (map[t.category] ?? 0) + t.cents;
      }
    }
    final list = map.entries.map((e) => CategoryTotal(e.key, e.value)).toList();
    list.sort((a, b) => b.cents.compareTo(a.cents));
    return list;
  }
}

class MonthTotals {
  final DateTime month;
  final int incomeCents;
  final int expenseCents;
  const MonthTotals(this.month, this.incomeCents, this.expenseCents);
}

class CategoryTotal {
  final String category;
  final int cents;
  const CategoryTotal(this.category, this.cents);
}

class BudgetStatus {
  final String category;
  final int limitCents;
  final int spentCents;
  const BudgetStatus(this.category, this.limitCents, this.spentCents);

  /// 0 to 100+ (can go over 100 when you overspend).
  int get percent =>
      limitCents <= 0 ? 0 : (spentCents * 100 / limitCents).round();

  int get remainingCents => limitCents - spentCents;
  bool get isOver => spentCents > limitCents;
}
