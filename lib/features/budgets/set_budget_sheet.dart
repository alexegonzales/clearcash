import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/tx_store.dart';

/// Opens the "Set budget" form from the bottom of the screen.
/// Pass [category] to open it on a category that already has a budget.
Future<void> showSetBudgetSheet(BuildContext context, {String? category}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.black, width: kBorder),
    ),
    builder: (_) => _SetBudgetSheet(category: category),
  );
}

class _SetBudgetSheet extends StatefulWidget {
  final String? category;
  const _SetBudgetSheet({this.category});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  late String _category;
  final _amount = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _select(widget.category ?? expenseCategories.first.name);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Picks a category and fills in its current limit, if it has one.
  void _select(String name) {
    _category = name;
    final cents = TxStore.instance.budgets[name];
    if (cents == null) {
      _amount.text = '';
    } else {
      _amount.text = cents % 100 == 0
          ? '${cents ~/ 100}'
          : (cents / 100).toStringAsFixed(2);
    }
    _error = null;
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a limit greater than 0.');
      return;
    }
    await TxStore.instance.setBudget(_category, (value * 100).round());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await TxStore.instance.setBudget(_category, 0);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = TxStore.instance.budgets.containsKey(_category);
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
                  Text('SET BUDGET', style: uStyle(14)),
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
              Text('CATEGORY', style: uStyle(11)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final c in expenseCategories)
                    GestureDetector(
                      onTap: () => setState(() => _select(c.name)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.name == _category
                              ? AppColors.cyan
                              : AppColors.white,
                          border: Border.all(color: AppColors.black, width: 3),
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
                          '${c.icon} ${c.name}'
                          '${TxStore.instance.budgets.containsKey(c.name) ? ' ✓' : ''}',
                          style: mStyle(12, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              BrutalInput(
                label: 'Monthly limit (₱)',
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
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
                label: hasBudget ? 'Update budget' : 'Save budget',
                color: AppColors.green,
                onPressed: _save,
              ),
              if (hasBudget) ...[
                const SizedBox(height: 18),
                BrutalButton(
                  label: 'Remove budget',
                  color: AppColors.pink,
                  onPressed: _remove,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
