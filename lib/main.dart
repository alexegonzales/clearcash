import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brutal_widgets.dart';

void main() => runApp(const ClearCashApp());

class ClearCashApp extends StatelessWidget {
  const ClearCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PreviewScreen(),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ClearCash', style: t.headlineLarge),
              const SizedBox(height: 4),
              Text('Your Money, Crystal Clear', style: t.bodyMedium),
              const SizedBox(height: 28),
              BrutalCard(
                color: AppColors.cyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL BALANCE', style: t.bodyMedium),
                    const SizedBox(height: 8),
                    Text('₱12,450.00', style: t.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const BrutalInput(label: 'Email'),
              const SizedBox(height: 28),
              BrutalButton(label: 'Log In', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}