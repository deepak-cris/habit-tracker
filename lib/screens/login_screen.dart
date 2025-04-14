import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart'; // Import AuthState
import 'signup_screen.dart'; // Import SignUpScreen
import 'forgot_password_screen.dart'; // Import ForgotPasswordScreen

class LoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;
  const LoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Connect to the actual AuthNotifier method
  Future<void> _loginWithEmail() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }
    // If valid, set loading and call the notifier
    setState(() => _isLoading = true);
    await ref
        .read(authProvider.notifier)
        .signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    // Check if still mounted and if an error occurred after the await
    if (mounted) {
      final currentState = ref.read(authProvider);
      // Stop loading indicator ONLY if the state is still error after the call
      // (If successful, navigation happens via listener, if still loading, listener handles it)
      if (currentState.maybeWhen(error: (_) => true, orElse: () => false)) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to handle loading indicator and errors
    ref.listen<AuthState>(authProvider, (_, next) {
      if (mounted) {
        setState(() {
          _isLoading = next.maybeWhen(loading: () => true, orElse: () => false);
        });
        // Show error SnackBar if state becomes error
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

    // Watch the state to potentially display initial/passed error messages
    final authState = ref.watch(authProvider);
    String? displayErrorMessage = widget.errorMessage;
    // Override with error from state if it exists and we are not loading
    if (!_isLoading) {
      authState.maybeWhen(
        error: (message) => displayErrorMessage = message,
        orElse: () {},
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Habit Tracker',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Email Field
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
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              // Disable while loading
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Email Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _loginWithEmail, // Disable while loading
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                const SizedBox(height: 24),

                // Divider OR
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      width: 24,
                      height: 24,
                    ),
                    label: const Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        _isLoading
                            ? null
                            : () =>
                                ref
                                    .read(authProvider.notifier)
                                    .signInWithGoogle(),
                  ),
                ),
                const SizedBox(height: 20),

                // Anonymous Sign-In Button
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () =>
                              ref
                                  .read(authProvider.notifier)
                                  .signInAnonymously(),
                  child: const Text('Continue Anonymously'),
                ),
                const SizedBox(height: 20),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // Disable while loading
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),

                // Display Error Message (if relevant and not loading)
                if (displayErrorMessage != null && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      displayErrorMessage ?? '', // Provide empty string if null
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
