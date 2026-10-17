import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final mono = GoogleFonts.spaceMonoTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.mint,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        surface: AppColors.mint,
      ),
      textTheme: mono.copyWith(
        headlineLarge: GoogleFonts.unbounded(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.black,
        ),
        headlineMedium: GoogleFonts.unbounded(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        bodyMedium: GoogleFonts.spaceMono(fontSize: 14, color: AppColors.black),
      ),
    );
  }
}
