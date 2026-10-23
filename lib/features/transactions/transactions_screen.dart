import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_tabs.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/models/money_tx.dart';
import '../../data/tx_store.dart';
import 'add_transaction_screen.dart';

/// All transactions with search and an All / Expenses / Income filter.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  int _filter = 0; // 0 all, 1 expenses, 2 income

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(MoneyTx t) {
    if (_filter == 1 && t.isIncome) return false;
    if (_filter == 2 && !t.isIncome) return false;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.note.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q) ||
        (t.cents / 100).toString().contains(q);
  }

  void _edit(MoneyTx t) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final list = TxStore.instance.items.where(_matches).toList();
        return Column(
          children: [
            BrutalTopBar(
              title: 'Transactions',
              subtitle: '${TxStore.instance.items.length} TOTAL',
              color: AppColors.mint,
            ),
            BrutalTabStrip(
              labels: const ['ALL', 'EXPENSES', 'INCOME'],
              index: _filter,
              onTap: (i) => setState(() => _filter = i),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 90),
                children: [
                  BrutalInput(
                    label: 'Search note, category or amount',
                    controller: _search,
                  ),
                  const SizedBox(height: 22),
                  if (list.isEmpty)
                    BrutalCard(
                      color: AppColors.yellow,
                      child: Text(
                        TxStore.instance.items.isEmpty
                            ? 'No transactions yet. Tap + to add your first one.'
                            : 'Nothing matches your search.',
                        style: mStyle(12, weight: FontWeight.w700),
                      ),
                    )
                  else
                    BrutalListCard(
                      children: [
                        for (final t in list)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _edit(t),
                            child: TxTile(
                              icon: categoryByName(t.category).icon,
                              iconColor: categoryByName(t.category).color,
                              name: t.note.isEmpty ? t.category : t.note,
                              category:
                                  '${t.category} • ${friendlyDate(t.date)}',
                              amount:
                                  '${t.isIncome ? '+' : '-'}${formatPeso(t.cents)}',
                              income: t.isIncome,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
