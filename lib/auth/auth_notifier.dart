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

  Future<void> signInAnonymously() async {
    try {
      state = const AuthState.loading();
      await _auth.signInAnonymously();
      // Auth state listener in checkAuthStatus will update state to authenticated
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Anonymous sign-in failed');
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Listener updates state to authenticated
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Login failed');
    } catch (e) {
      state = AuthState.error('An unexpected error occurred: $e');
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      state = const AuthState.loading();
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Listener updates state to authenticated
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'Sign up failed');
    } catch (e) {
      state = AuthState.error('An unexpected error occurred: $e');
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      print("Error sending password reset email: ${e.message}");
      return false; // Indicate failure
    } catch (e) {
      print("Unexpected error sending password reset email: $e");
      return false;
    }
  }

  // --- Phone Authentication Methods ---

  // Method to initiate phone number verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken, // Add optional parameter
  }) async {
    // REMOVE setting global loading state here. Let UI handle local loading.
    // state = const AuthState.loading();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken, // Pass the token
        timeout: const Duration(
          seconds: 120,
        ), // Increase timeout to 120 seconds
      );
      // Note: State is not set to success here, as the flow continues in callbacks
    } on FirebaseAuthException catch (e) {
      // Set error state if verification initiation fails
      state = AuthState.error(
        e.message ?? 'Phone verification failed: ${e.code}',
      );
    } catch (e) {
      // Set error state for other unexpected errors
      state = AuthState.error(
        'An unexpected error occurred during phone verification: $e',
      );
    }
  }

  // Method to sign in using the credential obtained after OTP verification
  Future<void> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      state = const AuthState.loading();
      await _auth.signInWithCredential(credential);
      // Explicitly set state to authenticated after successful sign-in
      final user = _auth.currentUser;
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state =
            const AuthState.unauthenticated(); // Handle unexpected null user
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(e.message ?? 'OTP Sign in failed');
    } catch (e) {
      state = AuthState.error('An unexpected error occurred: $e');
    }
  }
  // --- End Phone Authentication Methods ---

  Future<void> signOut() async {
    // If the user is anonymous, delete the account on sign out
    // Otherwise, they can't easily sign back in to the same anonymous account
    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.currentUser?.delete();
    }
    await _auth.signOut();
    await _googleSignIn
        .signOut(); // Also sign out from Google if previously used
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..checkAuthStatus();
});
