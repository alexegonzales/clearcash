import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import 'auth_service.dart';

/// "OR" divider plus the "Continue with Google" button.
/// It hides itself where Google sign-in isn't available.
class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await AuthService().signInWithGoogle();
      // The router moves to Home automatically after a successful sign-in.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthService.friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.googleAvailable) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppColors.black, thickness: 2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: uStyle(11)),
            ),
            const Expanded(
              child: Divider(color: AppColors.black, thickness: 2),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: BrutalButton(
            label: _loading ? 'Please wait...' : 'Continue with Google',
            color: AppColors.white,
            onPressed: _loading ? null : _signIn,
          ),
        ),
      ],
    );
  }
}
