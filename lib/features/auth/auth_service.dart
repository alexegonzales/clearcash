import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  /// Google sign-in works on Chrome, other browsers and Android. It is hidden
  /// on iPhone web apps, where Safari blocks the sign-in window.
  static bool get googleAvailable =>
      !(kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
  }

  Future<void> logIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Returns false if the user closed the Google window without signing in.
  Future<bool> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return false;
      rethrow;
    }
  }

  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'canceled',
    'user-cancelled',
  };

  Future<void> sendReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logOut() => _auth.signOut();

  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks wrong.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'That email already has an account.';
        case 'account-exists-with-different-credential':
          return 'This email already has an account. Log in with your email and password.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many tries. Please wait a bit.';
        case 'popup-blocked':
          return 'Your browser blocked the sign-in window. Allow pop-ups and try again.';
        case 'unauthorized-domain':
          return 'This website address is not allowed for sign-in yet.';
      }
      return e.message ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}
