import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

const double kBorder = 3;
const double kShadow = 4;

TextStyle uStyle(double size,
        {FontWeight weight = FontWeight.w700, Color color = AppColors.black}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: weight, color: color);

TextStyle mStyle(double size,
        {FontWeight weight = FontWeight.w400, Color color = AppColors.black}) =>
    GoogleFonts.spaceMono(fontSize: size, fontWeight: weight, color: color);

const _hardShadow = [
  BoxShadow(
      color: AppColors.black, offset: Offset(kShadow, kShadow), blurRadius: 0),
];
const _smallShadow = [
  BoxShadow(color: AppColors.black, offset: Offset(2, 2), blurRadius: 0),
];

// ---------------------------------------------------------------- basics

class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  const BrutalCard({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: _hardShadow,
      ),
      child: child,
    );
  }
}

class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.cyan,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? 0.0 : kShadow;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
            _pressed ? kShadow : 0, _pressed ? kShadow : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: AppColors.black, width: kBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.black,
              offset: Offset(offset, offset),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(widget.label.toUpperCase(), style: uStyle(14)),
      ),
    );
  }
}

class BrutalInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;

  const BrutalInput({
    super.key,
    required this.label,
    this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.black, width: kBorder),
    );
    return Container(
      decoration: const BoxDecoration(boxShadow: _hardShadow),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: mStyle(14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: mStyle(14),
          filled: true,
          fillColor: AppColors.white,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

// ------------------------------------------------- from the UI concept

/// Coloured header with a thick bottom border (title + small subtitle).
class BrutalTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  const BrutalTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.color = AppColors.mint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: const Border(
            bottom: BorderSide(color: AppColors.black, width: kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: uStyle(18, weight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: mStyle(10, color: AppColors.muted)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class BrutalTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const BrutalTag(
    this.text, {
    super.key,
    this.color = AppColors.cyan,
    this.textColor = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: _smallShadow,
      ),
      child: Text(text, style: uStyle(9, color: textColor)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? link;
  final VoidCallback? onLinkTap;

  const SectionHeader(this.title, {super.key, this.link, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.black, width: kBorder)),
          ),
          child: Text(title, style: uStyle(12)),
        ),
        if (link != null)
          GestureDetector(
            onTap: onLinkTap,
            child: Text(link!,
                style: mStyle(9).copyWith(decoration: TextDecoration.underline)),
          ),
      ],
    );
  }
}

class BrutalProgress extends StatelessWidget {
  final double percent; // 0 - 100
  final Color color;

  const BrutalProgress({super.key, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (percent / 100).clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: const Border(
                  right: BorderSide(color: AppColors.black, width: 3)),
            ),
          ),
        ),
      ),
    );
  }
}

class BalancePill {
  final String label;
  final String amount;
  final Color? color;
  const BalancePill(this.label, this.amount, [this.color]);
}

/// Big coloured card: label, large amount and white pills underneath.
class BalanceCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color decoColor;
  final List<BalancePill> pills;

  const BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.pills,
    this.color = AppColors.cyan,
    this.decoColor = AppColors.lime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(6, 6), blurRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.5,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: decoColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: mStyle(10, color: AppColors.muted)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(amount, style: uStyle(34, weight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < pills.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border:
                                Border.all(color: AppColors.black, width: 3),
                            boxShadow: _smallShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pills[i].label.toUpperCase(),
                                  style: mStyle(9, color: AppColors.muted)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  pills[i].amount,
                                  style: uStyle(14,
                                      color: pills[i].color ?? AppColors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertStrip extends StatelessWidget {
  final String text;
  const AlertStrip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: _hardShadow,
      ),
      child: Row(
        children: [
          const Text('⚠', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: mStyle(10, weight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatBox(this.label, this.value, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: _hardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: mStyle(9, color: AppColors.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: uStyle(16, weight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

/// White card whose rows are separated by thick black lines.
class BrutalListCard extends StatelessWidget {
  final List<Widget> children;
  const BrutalListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 2, thickness: 2, color: AppColors.black));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: kBorder),
        boxShadow: _hardShadow,
      ),
      child: Column(children: rows),
    );
  }
}

class TxTile extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String name;
  final String category;
  final String amount;
  final bool income;

  const TxTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.category,
    required this.amount,
    this.income = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor,
              border: Border.all(color: AppColors.black, width: 2),
              boxShadow: _smallShadow,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: uStyle(11)),
                Text(category.toUpperCase(),
                    style: mStyle(9, color: AppColors.muted)),
              ],
            ),
          ),
          Text(amount,
              style: uStyle(13,
                  color: income ? AppColors.income : AppColors.expense)),
        ],
      ),
    );
  }
}

class BrutalFab extends StatelessWidget {
  final VoidCallback onPressed;
  const BrutalFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.black,
          border: Border.all(color: AppColors.black, width: kBorder),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cyan, offset: Offset(kShadow, kShadow)),
          ],
        ),
        child: const Text('+',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.index, required this.onTap});

  static const _icons = ['🏠', '📋', '📊', '🎯', '⚙️'];
  static const _labels = ['Home', 'Txns', 'Reports', 'Goals', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.black, width: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == index ? AppColors.cyan : AppColors.white,
                        border: i < _icons.length - 1
                            ? const Border(
                                right: BorderSide(
                                    color: AppColors.black, width: 2))
                            : null,
                      ),
                      child: Opacity(
                        opacity: i == index ? 1 : 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_icons[i], style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 3),
                            Text(
                              _labels[i],
                              style: mStyle(9,
                                  weight: i == index
                                      ? FontWeight.w700
                                      : FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
