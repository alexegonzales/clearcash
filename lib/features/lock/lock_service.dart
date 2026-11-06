import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App lock: fingerprint / face, with the phone's own PIN or pattern as backup.
class LockService extends ChangeNotifier {
  LockService._();
  static final LockService instance = LockService._();

  static const _key = 'app_lock_enabled';
  final _auth = LocalAuthentication();

  /// The user turned the lock on.
  bool enabled = false;

  /// This phone can do fingerprint / face / PIN checks (false on Chrome).
  bool supported = false;

  /// True once the user has passed the check in this session.
  bool unlocked = true;

  /// True while the phone's prompt is open.
  bool _busy = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_key) ?? false;
    supported = await _checkSupported();
    // If the phone can no longer do checks (no screen lock set), don't trap the user.
    if (!supported) enabled = false;
    unlocked = !enabled;
    notifyListeners();
  }

  Future<bool> _checkSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Shows the phone's fingerprint / face / PIN prompt. True if it passed.
  Future<bool> authenticate({String reason = 'Unlock ClearCash'}) async {
    if (!supported) return true;
    _busy = true;
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (e) {
      debugPrint('Lock error: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Turns the lock on or off. The phone must verify you first.
  Future<bool> setEnabled(bool value) async {
    if (!supported) return false;
    final ok = await authenticate(
      reason: value
          ? 'Confirm to turn on the app lock'
          : 'Confirm to turn off the app lock',
    );
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    enabled = value;
    unlocked = true;
    notifyListeners();
    return true;
  }

  /// Locks the app again (used when the app went to the background).
  void lockNow() {
    if (!enabled || !unlocked || _busy) return;
    unlocked = false;
    notifyListeners();
  }

  /// Called after a successful check on the lock screen.
  void markUnlocked() {
    if (unlocked) return;
    unlocked = true;
    notifyListeners();
  }
}
