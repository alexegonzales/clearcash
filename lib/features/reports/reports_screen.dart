import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_tabs.dart';
import '../../core/theme/brutal_widgets.dart';
import '../../data/tx_store.dart';

/// Reports & analytics, built from the real transactions.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _tab = 0;

  static const _monthNames = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const _palette = [
    AppColors.teal,
    AppColors.lime,
    AppColors.sage,
    AppColors.sky,
    AppColors.seafoam,
    AppColors.cyan,
  ];

  double _h(int v, int maxV) {
    if (v <= 0 || maxV <= 0) return 0;
    final x = v / maxV * 96;
    return x < 3 ? 3 : x;
  }

  String _compact(int cents) {
    final pesos = cents / 100;
    if (pesos >= 1000) return '₱${(pesos / 1000).toStringAsFixed(1)}k';
    return '₱${pesos.round()}';
  }

  Widget _bar(double h, Color c) {
    if (h == 0) return const Expanded(child: SizedBox.shrink());
    return Expanded(
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
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
      Flexible(child: Text(text, style: mStyle(9))),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TxStore.instance,
      builder: (context, _) {
        final s = TxStore.instance;
        final months = s.lastSixMonths();
        final cats = s.expenseByCategoryThisMonth();
        final now = DateTime.now();

        var maxV = 0;
        for (final m in months) {
          maxV = math.max(maxV, math.max(m.incomeCents, m.expenseCents));
        }

        // Donut data: top 5 categories + "Others"
        final top = cats.take(5).toList();
        final others = cats.skip(5).fold<int>(0, (a, c) => a + c.cents);
        final names = <String>[
          ...top.map((c) => c.category),
          if (others > 0) 'Others',
        ];
        final values = <double>[
          ...top.map((c) => c.cents.toDouble()),
          if (others > 0) others.toDouble(),
        ];
        final total = values.fold<double>(0, (a, b) => a + b);

        return Column(
          children: [
            BrutalTopBar(
              title: 'Reports',
              subtitle: '6-MONTH OVERVIEW',
              color: AppColors.teal,
              trailing: const BrutalTag(
                'PDF ↓',
                color: AppColors.black,
                textColor: AppColors.white,
              ),
            ),
            BrutalTabStrip(
              labels: const ['OVERVIEW', 'MONTHLY', 'YEARLY'],
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  BrutalHeaderCard(
                    title: 'INCOME VS EXPENSES',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          padding: const EdgeInsets.only(left: 4),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppColors.black,
                                width: 3,
                              ),
                              bottom: BorderSide(
                                color: AppColors.black,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < months.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _bar(
                                        _h(months[i].incomeCents, maxV),
                                        i == months.length - 1
                                            ? AppColors.cyan
                                            : AppColors.teal,
                                      ),
                                      const SizedBox(width: 2),
                                      _bar(
                                        _h(months[i].expenseCents, maxV),
                                        i == months.length - 1
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
                            for (var i = 0; i < months.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _monthNames[months[i].month.month - 1],
                                  textAlign: TextAlign.center,
                                  style: mStyle(
                                    8,
                                    weight: i == months.length - 1
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: i == months.length - 1
                                        ? AppColors.black
                                        : AppColors.muted,
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
                        if (maxV == 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add transactions to see your chart.',
                            style: mStyle(10, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  BrutalHeaderCard(
                    title: 'SPENDING BREAKDOWN — ${_monthNames[now.month - 1]}',
                    child: total == 0
                        ? Text(
                            'No expenses this month yet.',
                            style: mStyle(11, weight: FontWeight.w700),
                          )
                        : Row(
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(90, 90),
                                      painter: _DonutPainter(values, [
                                        for (var i = 0; i < values.length; i++)
                                          _palette[i % _palette.length],
                                      ]),
                                    ),
                                    Text(
                                      _compact(total.round()),
                                      style: uStyle(8),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < names.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        child: _legend(
                                          '${names[i]} — ${(values[i] / total * 100).round()}%',
                                          _palette[i % _palette.length],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class _DonutPainter extends CustomPainter {
  final List<double> parts;
  final List<Color> colors;

  _DonutPainter(this.parts, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const ring = 22.0;
    final r = size.width / 2 - ring / 2 - 1;
    final rect = Rect.fromCircle(center: c, radius: r);
    final total = parts.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < parts.length; i++) {
      final sweep = parts[i] / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring
          ..color = colors[i],
      );
      start += sweep;
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.black;
    canvas.drawCircle(c, r + ring / 2, line);
    canvas.drawCircle(c, r - ring / 2, line);

    start = -math.pi / 2;
    for (var i = 0; i < parts.length; i++) {
      final dir = Offset(math.cos(start), math.sin(start));
      canvas.drawLine(c + dir * (r - ring / 2), c + dir * (r + ring / 2), line);
      start += parts[i] / total * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.parts != parts || old.colors != colors;
}
