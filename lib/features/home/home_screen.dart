import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../auth/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrutalCard(
                color: AppColors.cyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.displayName ?? 'there'}!',
                      style: t.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(user?.email ?? '', style: t.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Home Dashboard (coming soon)', style: t.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              BrutalButton(
                label: 'Log Out',
                color: AppColors.white,
                onPressed: () => AuthService().logOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
