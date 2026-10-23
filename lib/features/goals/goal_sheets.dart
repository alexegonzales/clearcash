import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/goal.dart';
import '../../data/tx_store.dart';

const _goalIcons = ['🎯', '💻', '🏖', '🚨', '🏠', '📱', '🚗', '🎓', '💍', '🎁'];

/// "12,500.50" -> 1250050. Returns null if empty, invalid or not above 0.
int? _parseCents(String text) {
  final v = double.tryParse(text.replaceAll(',', '').trim());
  if (v == null || v <= 0) return null;
  return (v * 100).round();
}

String _plain(int cents) =>
    cents % 100 == 0 ? '${cents ~/ 100}' : (cents / 100).toStringAsFixed(2);

/// Create a new goal, or edit/delete an existing one.
Future<void> showGoalSheet(BuildContext context, {Goal? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.black, width: kBorder),
    ),
    builder: (_) => _GoalSheet(existing: existing),
  );
}

/// Add money to a goal, or take some back out.
Future<void> showAddMoneySheet(BuildContext context, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.black, width: kBorder),
    ),
    builder: (_) => _AddMoneySheet(goal: goal),
  );
}

// ---------------------------------------------------------------- goal form

class _GoalSheet extends StatefulWidget {
  final Goal? existing;
  const _GoalSheet({this.existing});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late String _icon;
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController();
  final _due = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _icon = e?.icon ?? _goalIcons.first;
    if (e != null) {
      _name.text = e.name;
      _target.text = _plain(e.targetCents);
      _due.text = e.due;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = _parseCents(_target.text);
    if (name.isEmpty) {
      setState(() => _error = 'Give your goal a name.');
      return;
    }
    if (target == null) {
      setState(() => _error = 'Enter a target amount greater than 0.');
      return;
    }
    var startSaved = 0;
    if (widget.existing == null && _saved.text.trim().isNotEmpty) {
      final s = _parseCents(_saved.text);
      if (s == null) {
        setState(
          () =>
              _error = 'Enter a valid amount saved so far, or leave it empty.',
        );
        return;
      }
      startSaved = s;
    }
    final e = widget.existing;
    await TxStore.instance.saveGoal(
      Goal(
        id: e?.id ?? const Uuid().v4(),
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        name: name,
        icon: _icon,
        targetCents: target,
        savedCents: e?.savedCents ?? startSaved,
        due: _due.text.trim(),
        createdAt: e?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TxStore.instance.removeGoal(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(editing ? 'EDIT GOAL' : 'NEW GOAL', style: uStyle(14)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const BrutalTag(
                      'CLOSE',
                      color: AppColors.black,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('ICON', style: uStyle(11)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final i in _goalIcons)
                    GestureDetector(
                      onTap: () => setState(() => _icon = i),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == _icon ? AppColors.cyan : AppColors.white,
                          border: Border.all(color: AppColors.black, width: 3),
                          boxShadow: i == _icon
                              ? const [
                                  BoxShadow(
                                    color: AppColors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(i, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              BrutalInput(label: 'Goal name', controller: _name),
              const SizedBox(height: 22),
              BrutalInput(
                label: 'Target amount (₱)',
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (!editing) ...[
                const SizedBox(height: 22),
                BrutalInput(
                  label: 'Already saved (₱, optional)',
                  controller: _saved,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              BrutalInput(
                label: 'Due (optional, e.g. Jun 2027)',
                controller: _due,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: mStyle(
                    11,
                    weight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BrutalButton(
                label: editing ? 'Update goal' : 'Save goal',
                color: AppColors.green,
                onPressed: _save,
              ),
              if (editing) ...[
                const SizedBox(height: 18),
                BrutalButton(
                  label: 'Delete goal',
                  color: AppColors.pink,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ add money form

class _AddMoneySheet extends StatefulWidget {
  final Goal goal;
  const _AddMoneySheet({required this.goal});

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _apply(bool add) async {
    final cents = _parseCents(_amount.text);
    if (cents == null) {
      setState(() => _error = 'Enter an amount greater than 0.');
      return;
    }
    await TxStore.instance.addToGoal(widget.goal.id, add ? cents : -cents);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.goal;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${g.icon} ${g.name}', style: uStyle(14)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const BrutalTag(
                      'CLOSE',
                      color: AppColors.black,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${formatPeso(g.savedCents)} saved of ${formatPeso(g.targetCents)}',
                style: mStyle(12, color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              BrutalInput(
                label: 'Amount (₱)',
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: mStyle(
                    11,
                    weight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BrutalButton(
                label: 'Add money',
                color: AppColors.green,
                onPressed: () => _apply(true),
              ),
              const SizedBox(height: 18),
              BrutalButton(
                label: 'Take out',
                color: AppColors.pink,
                onPressed: () => _apply(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
