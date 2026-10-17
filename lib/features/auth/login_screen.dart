import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _logIn() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _toast('Enter your email and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.logIn(email: _email.text, password: _password.text);
      // The router redirects to /home automatically.
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      _toast('Type your email first, then tap Forgot password.');
      return;
    }
    try {
      await _auth.sendReset(_email.text);
      _toast('Reset link sent. Check your email.');
    } catch (e) {
      _toast(AuthService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.mint,
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
              Text('Welcome back', style: t.headlineLarge),
              const SizedBox(height: 8),
              Text('Log in to see your money.', style: t.bodyMedium),
              const SizedBox(height: 32),
              BrutalInput(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              BrutalInput(
                label: 'Password',
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _forgot,
                child: Text(
                  'Forgot password?',
                  style: t.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              BrutalButton(
                label: _loading ? 'Please wait...' : 'Log In',
                onPressed: _loading ? null : _logIn,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Text(
                    'No account? Sign up',
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
