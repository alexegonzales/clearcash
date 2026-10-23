import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/tx_store.dart';

/// Home / Dashboard, reading real data from the local database.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onSeeAll;
  const HomeScreen({super.key, this.onSeeAll});

  static const _months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_months[now.month - 1]} ${now.year}';

    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final s = TxStore.instance;
        final recent = s.items.take(3).toList();
        final saved = s.monthIncomeCents - s.monthExpenseCents;
        final statuses = s.budgetStatuses();
        final worst = statuses.isEmpty ? null : statuses.first;

        return Column(
          children: [
            BrutalTopBar(
              title: 'ClearCash 💰',
              subtitle: monthLabel,
              color: AppColors.mint,
              trailing: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Text('😊', style: TextStyle(fontSize: 16)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                children: [
                  BalanceCard(
                    label: 'Total balance',
                    amount: formatPeso(s.balanceCents),
                    color: AppColors.cyan,
                    pills: [
                      BalancePill(
                        'Income',
                        '+${formatPeso(s.monthIncomeCents)}',
                        AppColors.income,
                      ),
                      BalancePill(
                        'Expenses',
                        '-${formatPeso(s.monthExpenseCents)}',
                        AppColors.expense,
                      ),
                    ],
                  ),
                  if (worst != null && worst.percent >= 85) ...[
                    const SizedBox(height: 14),
                    AlertStrip(
                      worst.isOver
                          ? '${worst.category} budget is over the limit!'
                          : '${worst.category} budget is ${worst.percent}% used!',
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: StatBox(
                          'This week',
                          formatPeso(s.weekExpenseCents),
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatBox(
                          'Saved (mo.)',
                          formatPeso(saved < 0 ? 0 : saved),
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatBox(
                          'Goals',
                          '${s.goals.length} 🎯',
                          color: AppColors.sage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    'RECENT',
                    link: 'See all →',
                    onLinkTap: onSeeAll,
                  ),
                  const SizedBox(height: 10),
                  if (recent.isEmpty)
                    BrutalCard(
                      color: AppColors.yellow,
                      child: Text(
                        'No transactions yet. Tap + to add your first one.',
                        style: mStyle(12, weight: FontWeight.w700),
                      ),
                    )
                  else
                    BrutalListCard(
                      children: [
                        for (final t in recent)
                          TxTile(
                            icon: categoryByName(t.category).icon,
                            iconColor: categoryByName(t.category).color,
                            name: t.note.isEmpty ? t.category : t.note,
                            category: '${t.category} • ${friendlyDate(t.date)}',
                            amount:
                                '${t.isIncome ? '+' : '-'}${formatPeso(t.cents)}',
                            income: t.isIncome,
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
