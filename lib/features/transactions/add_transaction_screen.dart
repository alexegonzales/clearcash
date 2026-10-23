import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/models/money_tx.dart';
import '../../data/tx_store.dart';

/// Add a new transaction, or edit/delete an existing one.
class AddTransactionScreen extends StatefulWidget {
  final MoneyTx? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool _income;
  late String _category;
  late DateTime _date;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _income = e?.isIncome ?? false;
    _category =
        e?.category ??
        (_income ? incomeCategories : expenseCategories).first.name;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      _amount.text = e.cents % 100 == 0
          ? '${e.cents ~/ 100}'
          : (e.cents / 100).toStringAsFixed(2);
      _note.text = e.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      _toast('Enter an amount greater than 0.');
      return;
    }
    setState(() => _saving = true);
    final e = widget.existing;
    final tx = MoneyTx(
      id: e?.id ?? const Uuid().v4(),
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      isIncome: _income,
      cents: (value * 100).round(),
      category: _category,
      note: _note.text.trim(),
      date: _date,
      createdAt: e?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    await TxStore.instance.save(tx);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
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
      await TxStore.instance.remove(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _typeButton(String label, bool income) {
    final selected = _income == income;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _income = income;
          _category =
              (income ? incomeCategories : expenseCategories).first.name;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (income ? AppColors.green : AppColors.pink)
                : AppColors.white,
            border: Border.all(color: AppColors.black, width: kBorder),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.black,
                      offset: Offset(kShadow, kShadow),
                    ),
                  ]
                : null,
          ),
          child: Text(label, style: uStyle(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _income ? incomeCategories : expenseCategories;
    final editing = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          BrutalTopBar(
            title: editing ? 'Edit Transaction' : 'Add Transaction',
            subtitle: 'EVERY PESO COUNTS',
            color: _income ? AppColors.green : AppColors.cyan,
            trailing: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const BrutalTag(
                'CLOSE',
                color: AppColors.black,
                textColor: AppColors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    _typeButton('EXPENSE', false),
                    const SizedBox(width: 14),
                    _typeButton('INCOME', true),
                  ],
                ),
                const SizedBox(height: 24),
                BrutalInput(
                  label: 'Amount (₱)',
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text('CATEGORY', style: uStyle(11)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final c in cats)
                      GestureDetector(
                        onTap: () => setState(() => _category = c.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: c.name == _category
                                ? AppColors.cyan
                                : AppColors.white,
                            border: Border.all(
                              color: AppColors.black,
                              width: 3,
                            ),
                            boxShadow: c.name == _category
                                ? const [
                                    BoxShadow(
                                      color: AppColors.black,
                                      offset: Offset(2, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '${c.icon} ${c.name}',
                            style: mStyle(12, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                BrutalInput(label: 'Note (optional)', controller: _note),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(
                        color: AppColors.black,
                        width: kBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          offset: Offset(kShadow, kShadow),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DATE', style: uStyle(11)),
                        Text(friendlyDate(_date), style: mStyle(13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BrutalButton(
                  label: _saving ? 'Saving...' : 'Save',
                  color: _income ? AppColors.green : AppColors.cyan,
                  onPressed: _saving ? null : _save,
                ),
                if (editing) ...[
                  const SizedBox(height: 20),
                  BrutalButton(
                    label: 'Delete',
                    color: AppColors.pink,
                    onPressed: _delete,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
