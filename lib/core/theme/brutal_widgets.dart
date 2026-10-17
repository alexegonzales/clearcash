import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

const double kBorder = 3;
const double kShadow = 4;

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
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(kShadow, kShadow),
            blurRadius: 0,
          ),
        ],
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
          _pressed ? kShadow : 0,
          _pressed ? kShadow : 0,
          0,
        ),
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
        child: Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
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
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: AppColors.black, offset: Offset(kShadow, kShadow)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceMono(color: AppColors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.spaceMono(color: AppColors.black),
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
