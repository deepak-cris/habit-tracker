import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart'; // Import AuthState

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message; // To show success or error messages

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null; // Clear previous message
      });

      // Call actual method from AuthNotifier
      final success = await ref
          .read(authProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());

      // Determine message based on success
      String messageToShow =
          success
              ? 'Password reset email sent (if account exists).'
              : 'Failed to send reset email. Please check the email address.';

      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = messageToShow;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No need to listen to authProvider state changes here usually,
    // as sending a reset email doesn't change the auth state itself.
    // We manage loading/message state locally.

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Enter your email address to receive a password reset link.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email';
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
                        onPressed: _sendResetEmail, // Connect to placeholder
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Send Reset Email'),
                      ),
                    ),
                const SizedBox(height: 16),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color:
                            _message!.startsWith('Failed')
                                ? Colors.red
                                : Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(), // Go back to Login
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
