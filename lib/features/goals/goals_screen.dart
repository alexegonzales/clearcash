import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_tabs.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/models/goal.dart';
import '../../data/tx_store.dart';
import '../budgets/budgets_view.dart';
import '../budgets/set_budget_sheet.dart';
import 'goal_sheets.dart';

/// Goals tab. It also holds the Budgets view behind a GOALS / BUDGETS switch.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _tab = 0;

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

  String _budgetSubtitle() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final left = lastDay - now.day;
    final leftText = left == 0
        ? 'LAST DAY'
        : left == 1
        ? '1 DAY LEFT'
        : '$left DAYS LEFT';
    return '${_months[now.month - 1]} ${now.year} — $leftText';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final count = TxStore.instance.goals.length;
        return Column(
          children: [
            if (_tab == 0)
              BrutalTopBar(
                title: 'Goals 🎯',
                subtitle: count == 1 ? '1 ACTIVE GOAL' : '$count ACTIVE GOALS',
                color: AppColors.lime,
                trailing: GestureDetector(
                  onTap: () => showGoalSheet(context),
                  child: const BrutalTag(
                    '+NEW',
                    color: AppColors.black,
                    textColor: AppColors.white,
                  ),
                ),
              )
            else
              BrutalTopBar(
                title: 'Budgets',
                subtitle: _budgetSubtitle(),
                color: AppColors.green,
                trailing: GestureDetector(
                  onTap: () => showSetBudgetSheet(context),
                  child: const BrutalTag('+ADD', color: AppColors.cyan),
                ),
              ),
            BrutalTabStrip(
              labels: const ['GOALS', 'BUDGETS'],
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: _tab == 0 ? const _GoalsView() : const BudgetsView(),
            ),
          ],
        );
      },
    );
  }
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  static const _bg = [AppColors.mint, AppColors.green, AppColors.teal];
  static const _iconBg = [AppColors.lime, AppColors.teal, AppColors.cyan];
  static const _tagBg = [AppColors.teal, AppColors.sky, AppColors.sage];
  static const _barBg = [AppColors.seafoam, AppColors.sky, AppColors.sage];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final s = TxStore.instance;
        final goals = s.goals;
        final saved = s.totalSavedCents;
        final target = s.totalGoalTargetCents;
        final overall = target <= 0 ? 0 : (saved * 100 / target).round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          children: [
            BalanceCard(
              label: 'Total saved',
              amount: formatPeso(saved),
              color: AppColors.seafoam,
              decoColor: AppColors.green,
              pills: [
                BalancePill('Target', formatPeso(target)),
                BalancePill('Progress', '$overall% done', AppColors.income),
              ],
            ),
            const SizedBox(height: 14),
            if (goals.isEmpty)
              BrutalCard(
                color: AppColors.yellow,
                child: Text(
                  'No goals yet. Tap "New goal" to start saving for something.',
                  style: mStyle(12, weight: FontWeight.w700),
                ),
              )
            else
              for (var i = 0; i < goals.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _GoalCard(
                  goal: goals[i],
                  bg: _bg[i % 3],
                  iconColor: _iconBg[i % 3],
                  tagColor: _tagBg[i % 3],
                  barColor: _barBg[i % 3],
                ),
              ],
            const SizedBox(height: 24),
            BrutalButton(
              label: 'New goal',
              color: AppColors.cyan,
              onPressed: () => showGoalSheet(context),
            ),
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final Color bg;
  final Color iconColor;
  final Color tagColor;
  final Color barColor;

  const _GoalCard({
    required this.goal,
    required this.bg,
    required this.iconColor,
    required this.tagColor,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal.percent;
    final targetText =
        'Target: ${formatPeso(goal.targetCents)}'
        '${goal.due.isEmpty ? ' • Ongoing' : ' • Due: ${goal.due}'}';
    final savedText = goal.isDone
        ? '🎉 Goal reached! ${formatPeso(goal.savedCents)} saved'
        : '${formatPeso(goal.savedCents)} saved of ${formatPeso(goal.targetCents)}';

    return GestureDetector(
      onTap: () => showAddMoneySheet(context, goal),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.black, width: kBorder),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(kShadow, kShadow)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                border: const Border(
                  bottom: BorderSide(color: AppColors.black, width: kBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconColor,
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name, style: uStyle(13)),
                        const SizedBox(height: 2),
                        Text(
                          targetText,
                          style: mStyle(10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BrutalTag('$pct%', color: tagColor),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => showGoalSheet(context, existing: goal),
                        child: const BrutalTag('EDIT', color: AppColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            border: const Border(
                              right: BorderSide(
                                color: AppColors.black,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(savedText, style: uStyle(11)),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the card to add money',
                    style: mStyle(9, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
