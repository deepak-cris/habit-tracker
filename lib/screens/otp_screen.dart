import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import 'dart:async'; // Import for Timer

class OTPScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken; // Add resendToken parameter

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken, // Make it optional
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _resendEnabled = false; // Track if resend is enabled
  int _start = 120; // Countdown timer value (120 seconds = 2 minutes)
  Timer? _timer; // Timer object

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  // --- Timer Logic ---
  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _resendEnabled = true; // Enable resend button
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // --- Resend OTP Logic ---
  Future<void> _resendOtp() async {
    if (_resendEnabled) {
      setState(() {
        _resendEnabled = false;
        _start = 120; // Reset timer
      });
      startTimer(); // Restart timer
      print("Resending OTP...");
      // Call verifyPhoneNumber again, passing the resendToken
      await ref
          .read(authProvider.notifier)
          .verifyPhoneNumber(
            phoneNumber: widget.phoneNumber,
            forceResendingToken: widget.resendToken, // Pass the resend token
            verificationCompleted: (PhoneAuthCredential credential) async {
              // Auto-retrieval or instant verification cases
              print("Phone verification completed automatically.");
              await ref
                  .read(authProvider.notifier)
                  .signInWithPhoneCredential(credential);
            },
            verificationFailed: (FirebaseAuthException e) {
              print("Phone verification failed: ${e.message}");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Phone verification failed: ${e.code}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            codeSent: (String verificationId, int? resendToken) {
              print("New OTP code sent. Verification ID: $verificationId");
              // No need to navigate again, we are already on the OTP screen
              // Just update the state (verificationId) if needed
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              print(
                "OTP auto-retrieval timed out. Verification ID: $verificationId",
              );
            },
          );
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final otp = _otpController.text.trim();
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otp,
        );
        // Attempt to sign in with the credential
        await ref
            .read(authProvider.notifier)
            .signInWithPhoneCredential(credential);
        // Listener in main/login screen will handle navigation on success
        // Pop the screen after successful sign-in
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Error is handled by the AuthNotifier state, no need to set isLoading false here
        // unless the error isn't caught by the listener quickly enough
        print("Error verifying OTP: $e");
        if (mounted) {
          // Optionally show a specific snackbar here if needed
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Invalid OTP or error occurred."), backgroundColor: Colors.red),
          // );
          // Ensure loading stops if error state doesn't trigger listener update fast enough
          final currentState = ref.read(authProvider);
          if (currentState.maybeWhen(error: (_) => true, orElse: () => false)) {
            setState(() => _isLoading = false);
          }
        }
      }
      // No need to set isLoading = false on success, navigation handles it
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for loading state changes
    ref.listen<AuthState>(authProvider, (_, next) {
      if (mounted) {
        setState(() {
          _isLoading = next.maybeWhen(loading: () => true, orElse: () => false);
        });
        // Handle errors shown by the notifier state
        next.maybeWhen(
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
          orElse: () {},
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Enter the 6-digit code sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    border: OutlineInputBorder(),
                    counterText: "", // Hide the counter
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 6) {
                      return 'Please enter the 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Verify OTP'),
                      ),
                    ),
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => Navigator.of(context).pop(), // Go back
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 20),
                // Resend OTP Button (conditionally enabled)
                _resendEnabled
                    ? TextButton(
                      onPressed: _resendOtp,
                      child: const Text('Resend OTP'),
                    )
                    : Text(
                      'Resend code in $_start seconds', // Show timer
                      style: const TextStyle(color: Colors.grey),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
