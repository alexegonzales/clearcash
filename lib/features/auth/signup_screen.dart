import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import 'auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signUp() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      _toast('Please fill in all fields.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      // The router redirects to /home automatically.
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.cyan,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/welcome'),
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
              ),
              const SizedBox(height: 16),
              Text('Create account', style: t.headlineLarge),
              const SizedBox(height: 8),
              Text('Start tracking in under a minute.', style: t.bodyMedium),
              const SizedBox(height: 32),
              BrutalInput(label: 'Name', controller: _name),
              const SizedBox(height: 24),
              BrutalInput(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              BrutalInput(
                label: 'Password (6+ characters)',
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: 32),
              BrutalButton(
                label: _loading ? 'Please wait...' : 'Create Account',
                color: AppColors.green,
                onPressed: _loading ? null : _signUp,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Already have an account? Log in',
                    style: t.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
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
