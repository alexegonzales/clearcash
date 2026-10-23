import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/categories.dart';
import '../../data/tx_store.dart';
import 'set_budget_sheet.dart';

/// Budget list (shown inside the Goals tab), built from real data.
class BudgetsView extends StatelessWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final s = TxStore.instance;
        final statuses = s.budgetStatuses();
        final total = s.totalBudgetCents;
        final spent = s.totalBudgetSpentCents;
        final remaining = total - spent;

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          children: [
            BalanceCard(
              label: 'Monthly budget',
              amount: formatPeso(total),
              color: AppColors.sage,
              decoColor: AppColors.mint,
              pills: [
                BalancePill('Spent', formatPeso(spent), AppColors.expense),
                BalancePill(
                  'Remaining',
                  formatPeso(remaining),
                  remaining >= 0 ? AppColors.income : AppColors.expense,
                ),
              ],
            ),
            if (statuses.isNotEmpty && statuses.first.percent >= 85) ...[
              const SizedBox(height: 14),
              AlertStrip(
                statuses.first.isOver
                    ? '${statuses.first.category} budget is over the limit!'
                    : '${statuses.first.category} budget is ${statuses.first.percent}% used!',
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.black,
                        width: kBorder,
                      ),
                    ),
                  ),
                  child: Text('CATEGORIES', style: uStyle(12)),
                ),
                BrutalTag('${statuses.length} ACTIVE', color: AppColors.mint),
              ],
            ),
            const SizedBox(height: 10),
            if (statuses.isEmpty)
              BrutalCard(
                color: AppColors.yellow,
                child: Text(
                  'No budgets yet. Tap "Set budget" to add your first one.',
                  style: mStyle(12, weight: FontWeight.w700),
                ),
              )
            else
              BrutalListCard(
                children: [for (final b in statuses) _BudgetRow(b)],
              ),
            const SizedBox(height: 24),
            BrutalButton(
              label: 'Set budget',
              color: AppColors.cyan,
              onPressed: () => showSetBudgetSheet(context),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetStatus s;
  const _BudgetRow(this.s);

  @override
  Widget build(BuildContext context) {
    final cat = categoryByName(s.category);
    final pct = s.percent;
    final tagColor = pct >= 85
        ? AppColors.pink
        : pct >= 60
        ? AppColors.yellow
        : AppColors.lime;
    final barColor = s.isOver
        ? AppColors.expense
        : pct >= 85
        ? AppColors.pink
        : AppColors.seafoam;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showSetBudgetSheet(context, category: s.category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(s.category, style: uStyle(11)),
                const SizedBox(width: 6),
                BrutalTag('$pct%', color: tagColor),
                const Spacer(),
                Text(
                  '${formatPeso(s.spentCents)} / ${formatPeso(s.limitCents)}',
                  style: mStyle(10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            BrutalProgress(percent: pct.toDouble(), color: barColor),
            if (s.isOver)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Over by ${formatPeso(-s.remainingCents)}',
                    style: mStyle(
                      10,
                      weight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
