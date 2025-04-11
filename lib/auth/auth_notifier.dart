import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthNotifier()
    : _auth = FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']),
      super(const AuthState.initial());

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    await Future.delayed(const Duration(seconds: 1)); // Initial loading delay
    _auth.authStateChanges().listen((user) {
      state =
          user != null
              ? AuthState.authenticated(user)
              : const AuthState.unauthenticated();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Google sign-in failed');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..checkAuthStatus();
});
