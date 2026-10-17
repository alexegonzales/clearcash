import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('💰', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('ClearCash', style: t.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Track spending. Set budgets. Hit your goals.',
                style: t.bodyMedium,
              ),
              const Spacer(),
              BrutalButton(
                label: 'Sign Up',
                color: AppColors.cyan,
                onPressed: () => context.go('/signup'),
              ),
              const SizedBox(height: 20),
              BrutalButton(
                label: 'Log In',
                color: AppColors.white,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
