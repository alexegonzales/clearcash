import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.darkTeal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'ClearCash',
              style: t.headlineLarge?.copyWith(color: AppColors.mint),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Money, Crystal Clear',
              style: t.bodyMedium?.copyWith(color: AppColors.mint),
            ),
          ],
        ),
      ),
    );
  }
}
