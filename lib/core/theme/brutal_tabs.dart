import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'brutal_widgets.dart';

/// Row of tabs under a top bar (like OVERVIEW / MONTHLY / YEARLY).
class BrutalTabStrip extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  const BrutalTabStrip({
    super.key,
    required this.labels,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.black, width: kBorder)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.cyan : AppColors.white,
                    border: i < labels.length - 1
                        ? const Border(
                            right: BorderSide(color: AppColors.black, width: 2))
                        : null,
                  ),
                  child: Opacity(
                    opacity: i == index ? 1 : 0.5,
                    child: Text(labels[i], style: uStyle(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White card with a black title strip on top.
class BrutalHeaderCard extends StatelessWidget {
  final String title;
  final Widget child;

  const BrutalHeaderCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(kShadow, kShadow)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(title,
                style: uStyle(11, color: AppColors.white)
                    .copyWith(letterSpacing: 1)),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}
