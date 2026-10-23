String _dateText(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// One income or expense entry. Money is stored in centavos (integers).
class MoneyTx {
  final String id;
  final String uid;
  final bool isIncome;
  final int cents;
  final String category;
  final String note;
  final DateTime date;
  final int createdAt;
  final bool synced; // used later for Firestore sync

  const MoneyTx({
    required this.id,
    required this.uid,
    required this.isIncome,
    required this.cents,
    required this.category,
    required this.note,
    required this.date,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'uid': uid,
    'type': isIncome ? 'income' : 'expense',
    'amount_cents': cents,
    'category': category,
    'note': note,
    'date': _dateText(date),
    'created_at': createdAt,
    'synced': synced ? 1 : 0,
  };

  factory MoneyTx.fromMap(Map<String, Object?> m) => MoneyTx(
    id: m['id'] as String,
    uid: m['uid'] as String,
    isIncome: m['type'] == 'income',
    cents: m['amount_cents'] as int,
    category: m['category'] as String,
    note: (m['note'] as String?) ?? '',
    date: DateTime.parse(m['date'] as String),
    createdAt: m['created_at'] as int,
    synced: (m['synced'] as int? ?? 0) == 1,
  );
}
