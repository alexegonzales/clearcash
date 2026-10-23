/// One savings goal. Money is stored in centavos (integers).
class Goal {
  final String id;
  final String uid;
  final String name;
  final String icon;
  final int targetCents;
  final int savedCents;
  final String due; // free text like "Jun 2026", or empty for ongoing
  final int createdAt;

  const Goal({
    required this.id,
    required this.uid,
    required this.name,
    required this.icon,
    required this.targetCents,
    required this.savedCents,
    required this.due,
    required this.createdAt,
  });

  int get percent =>
      targetCents <= 0 ? 0 : (savedCents * 100 / targetCents).round();

  int get remainingCents => targetCents - savedCents;
  bool get isDone => savedCents >= targetCents;

  Map<String, Object?> toMap() => {
    'id': id,
    'uid': uid,
    'name': name,
    'icon': icon,
    'target_cents': targetCents,
    'saved_cents': savedCents,
    'due': due,
    'created_at': createdAt,
  };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
    id: m['id'] as String,
    uid: m['uid'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String,
    targetCents: m['target_cents'] as int,
    savedCents: m['saved_cents'] as int,
    due: (m['due'] as String?) ?? '',
    createdAt: m['created_at'] as int,
  );
}
