import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_tabs.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/models/money_tx.dart';
import '../../data/tx_store.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _letters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

// ------------------------------------------------------------------ helpers

DateTime? _earliest(List<MoneyTx> items) {
  if (items.isEmpty) return null;
  var e = items.first.date;
  for (final t in items) {
    if (t.date.isBefore(e)) e = t.date;
  }
  return e;
}

List<MapEntry<String, int>> _expenseByCategory(Iterable<MoneyTx> items) {
  final map = <String, int>{};
  for (final t in items) {
    if (!t.isIncome) map[t.category] = (map[t.category] ?? 0) + t.cents;
  }
  final list = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return list;
}

Widget _picker({
  required String label,
  required bool canBack,
  required bool canForward,
  required VoidCallback onBack,
  required VoidCallback onForward,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Opacity(
        opacity: canBack ? 1 : 0.3,
        child: GestureDetector(
          onTap: canBack ? onBack : null,
          child: const BrutalTag('<', color: AppColors.cyan),
        ),
      ),
      Text(label, style: mStyle(13, weight: FontWeight.w700)),
      Opacity(
        opacity: canForward ? 1 : 0.3,
        child: GestureDetector(
          onTap: canForward ? onForward : null,
          child: const BrutalTag('>', color: AppColors.cyan),
        ),
      ),
    ],
  );
}

Widget _kv(String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: mStyle(10, color: AppColors.muted)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          v,
          textAlign: TextAlign.right,
          style: mStyle(11, weight: FontWeight.w700),
        ),
      ),
    ],
  ),
);

Widget _emptyCard(String text) => BrutalCard(
  color: AppColors.yellow,
  child: Text(text, style: mStyle(12, weight: FontWeight.w700)),
);

/// Category rows: icon, name, share %, amount and a progress bar.
Widget _categoryRows(List<MapEntry<String, int>> rows, int total) {
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 12),
          child: Builder(
            builder: (context) {
              final c = categoryByName(rows[i].key);
              final pct = total <= 0
                  ? 0
                  : (rows[i].value * 100 / total).round();
              return Column(
                children: [
                  Row(
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(rows[i].key, style: uStyle(11))),
                      BrutalTag('$pct%', color: c.color),
                      const SizedBox(width: 8),
                      Text(formatPeso(rows[i].value), style: mStyle(10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BrutalProgress(percent: pct.toDouble(), color: c.color),
                ],
              );
            },
          ),
        ),
    ],
  );
}

Widget _bar(double h, Color c) {
  if (h == 0) return const Expanded(child: SizedBox.shrink());
  return Expanded(
    child: Container(
      height: h,
      decoration: BoxDecoration(
        color: c,
        border: Border.all(color: AppColors.black, width: 2),
      ),
    ),
  );
}

double _h(int v, int maxV) {
  if (v <= 0 || maxV <= 0) return 0;
  final x = v / maxV * 92;
  return x < 3 ? 3 : x;
}

Widget _legend(String text, Color c) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        border: Border.all(color: AppColors.black, width: 2),
      ),
    ),
    const SizedBox(width: 4),
    Text(text, style: mStyle(9)),
  ],
);

// ------------------------------------------------------------------ MONTHLY

class MonthlyView extends StatefulWidget {
  const MonthlyView({super.key});

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrent {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final all = TxStore.instance.items;
        final first = _earliest(all);
        final canBack =
            first != null && _month.isAfter(DateTime(first.year, first.month));

        final inMonth = all
            .where(
              (t) => t.date.year == _month.year && t.date.month == _month.month,
            )
            .toList();

        var income = 0;
        var expense = 0;
        MoneyTx? biggest;
        for (final t in inMonth) {
          if (t.isIncome) {
            income += t.cents;
          } else {
            expense += t.cents;
            if (biggest == null || t.cents > biggest.cents) biggest = t;
          }
        }
        final cats = _expenseByCategory(inMonth);

        final now = DateTime.now();
        final days = _isCurrent
            ? now.day
            : DateTime(_month.year, _month.month + 1, 0).day;
        final label = '${_monthNames[_month.month - 1]} ${_month.year}';

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _picker(
              label: label,
              canBack: canBack,
              canForward: !_isCurrent,
              onBack: () => _shift(-1),
              onForward: () => _shift(1),
            ),
            const SizedBox(height: 16),
            BalanceCard(
              label: 'Net for ${_monthNames[_month.month - 1]}',
              amount: formatPeso(income - expense),
              color: AppColors.teal,
              decoColor: AppColors.cyan,
              pills: [
                BalancePill(
                  'Income',
                  '+${formatPeso(income)}',
                  AppColors.income,
                ),
                BalancePill(
                  'Expenses',
                  '-${formatPeso(expense)}',
                  AppColors.expense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (inMonth.isEmpty)
              _emptyCard('No transactions in $label.')
            else ...[
              if (cats.isNotEmpty) ...[
                BrutalHeaderCard(
                  title: 'SPENDING BY CATEGORY',
                  child: _categoryRows(cats, expense),
                ),
                const SizedBox(height: 16),
              ],
              BrutalHeaderCard(
                title: 'HIGHLIGHTS',
                child: Column(
                  children: [
                    _kv('Transactions', '${inMonth.length}'),
                    if (biggest != null)
                      _kv(
                        'Biggest expense',
                        '${biggest.note.isEmpty ? biggest.category : biggest.note}'
                            ' - ${formatPeso(biggest.cents)}',
                      ),
                    _kv(
                      _isCurrent ? 'Daily average so far' : 'Daily average',
                      formatPeso((expense / days).round()),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------- YEARLY

class YearlyView extends StatefulWidget {
  const YearlyView({super.key});

  @override
  State<YearlyView> createState() => _YearlyViewState();
}

class _YearlyViewState extends State<YearlyView> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final all = TxStore.instance.items;
        final now = DateTime.now();
        final first = _earliest(all);
        final canBack = first != null && _year > first.year;
        final isCurrentYear = _year == now.year;

        final inYear = all.where((t) => t.date.year == _year).toList();

        final incomes = List<int>.filled(12, 0);
        final expenses = List<int>.filled(12, 0);
        for (final t in inYear) {
          final m = t.date.month - 1;
          if (t.isIncome) {
            incomes[m] += t.cents;
          } else {
            expenses[m] += t.cents;
          }
        }
        final income = incomes.fold<int>(0, (a, b) => a + b);
        final expense = expenses.fold<int>(0, (a, b) => a + b);

        var maxV = 0;
        for (var i = 0; i < 12; i++) {
          if (incomes[i] > maxV) maxV = incomes[i];
          if (expenses[i] > maxV) maxV = expenses[i];
        }

        // highlights
        var topSpendMonth = -1;
        var bestSaveMonth = -1;
        for (var i = 0; i < 12; i++) {
          if (expenses[i] > 0 &&
              (topSpendMonth == -1 || expenses[i] > expenses[topSpendMonth])) {
            topSpendMonth = i;
          }
          if ((incomes[i] > 0 || expenses[i] > 0) &&
              (bestSaveMonth == -1 ||
                  incomes[i] - expenses[i] >
                      incomes[bestSaveMonth] - expenses[bestSaveMonth])) {
            bestSaveMonth = i;
          }
        }
        final monthsCounted = isCurrentYear ? now.month : 12;
        final cats = _expenseByCategory(inYear);
        final topCats = cats.take(5).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _picker(
              label: '$_year',
              canBack: canBack,
              canForward: !isCurrentYear,
              onBack: () => setState(() => _year--),
              onForward: () => setState(() => _year++),
            ),
            const SizedBox(height: 16),
            BalanceCard(
              label: 'Net for $_year',
              amount: formatPeso(income - expense),
              color: AppColors.sage,
              decoColor: AppColors.mint,
              pills: [
                BalancePill(
                  'Income',
                  '+${formatPeso(income)}',
                  AppColors.income,
                ),
                BalancePill(
                  'Expenses',
                  '-${formatPeso(expense)}',
                  AppColors.expense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (inYear.isEmpty)
              _emptyCard('No transactions in $_year.')
            else ...[
              BrutalHeaderCard(
                title: 'MONTH BY MONTH',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      padding: const EdgeInsets.only(left: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.black, width: 3),
                          bottom: BorderSide(color: AppColors.black, width: 3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 12; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _bar(
                                    _h(incomes[i], maxV),
                                    isCurrentYear && i == now.month - 1
                                        ? AppColors.cyan
                                        : AppColors.teal,
                                  ),
                                  _bar(
                                    _h(expenses[i], maxV),
                                    isCurrentYear && i == now.month - 1
                                        ? AppColors.pink
                                        : AppColors.sage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        for (var i = 0; i < 12; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _letters[i],
                              textAlign: TextAlign.center,
                              style: mStyle(
                                8,
                                weight: isCurrentYear && i == now.month - 1
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _legend('Income', AppColors.teal),
                        const SizedBox(width: 10),
                        _legend('Expenses', AppColors.sage),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BrutalHeaderCard(
                title: 'HIGHLIGHTS',
                child: Column(
                  children: [
                    _kv('Transactions', '${inYear.length}'),
                    _kv(
                      'Average monthly spending',
                      formatPeso((expense / monthsCounted).round()),
                    ),
                    if (topSpendMonth != -1)
                      _kv(
                        'Highest spending month',
                        '${_monthNames[topSpendMonth]} - ${formatPeso(expenses[topSpendMonth])}',
                      ),
                    if (bestSaveMonth != -1)
                      _kv(
                        'Best savings month',
                        '${_monthNames[bestSaveMonth]} - ${formatPeso(incomes[bestSaveMonth] - expenses[bestSaveMonth])}',
                      ),
                  ],
                ),
              ),
              if (topCats.isNotEmpty) ...[
                const SizedBox(height: 16),
                BrutalHeaderCard(
                  title: 'TOP CATEGORIES',
                  child: _categoryRows(topCats, expense),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
