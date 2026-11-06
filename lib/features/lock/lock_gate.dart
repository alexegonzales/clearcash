import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brutal_widgets.dart';
import '../auth/auth_service.dart';
import 'lock_service.dart';

/// Wraps the whole app. When the lock is on and the app is locked, it covers
/// everything with the lock screen. It locks again when the app goes to the
/// background.
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      LockService.instance.lockNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LockService.instance,
      builder: (context, _) {
        final lock = LockService.instance;
        final loggedIn = FirebaseAuth.instance.currentUser != null;
        final locked = lock.enabled && !lock.unlocked && loggedIn;
        return Stack(
          children: [
            widget.child,
            if (locked) const Positioned.fill(child: _LockScreen()),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // Ask for the fingerprint as soon as the lock screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    final ok = await LockService.instance.authenticate();
    _asking = false;
    if (ok) LockService.instance.markUnlocked();
  }

  Future<void> _logOut() async {
    await AuthService().logOut();
    LockService.instance.markUnlocked(); // lets the login screens show
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkTeal,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'ClearCash',
                style: uStyle(
                  28,
                  weight: FontWeight.w900,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 8),
              Text('Locked', style: mStyle(13, color: AppColors.mint)),
              const SizedBox(height: 40),
              BrutalButton(
                label: 'Unlock',
                color: AppColors.cyan,
                onPressed: _unlock,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _logOut,
                child: Text(
                  'Log out instead',
                  style: mStyle(
                    12,
                    color: AppColors.mint,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
