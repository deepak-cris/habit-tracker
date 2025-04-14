import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters if needed later
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for PhoneAuthCredential, FirebaseAuthException
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart'; // Import OTP Screen

class LoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;
  const LoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>(); // Separate key for phone form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Controller for phone number
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Initialize TabController
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _tabController.dispose(); // Dispose TabController
    super.dispose();
  }

  // --- Email Login Logic ---
  Future<void> _loginWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    await ref
        .read(authProvider.notifier)
        .signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    if (mounted &&
        ref
            .read(authProvider)
            .maybeWhen(error: (_) => true, orElse: () => false)) {
      setState(() => _isLoading = false);
    }
  }

  // --- Phone Login Logic ---
  Future<void> _loginWithPhone() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    // Get the 10-digit number and prepend +91
    final String rawPhoneNumber = _phoneController.text.trim();
    final String phoneNumberWithCountryCode = '+91$rawPhoneNumber';

    print("Attempting Phone Login for: $phoneNumberWithCountryCode");

    await ref
        .read(authProvider.notifier)
        .verifyPhoneNumber(
          phoneNumber: phoneNumberWithCountryCode, // Pass formatted number
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-retrieval or instant verification cases
            print("Phone verification completed automatically.");
            await ref
                .read(authProvider.notifier)
                .signInWithPhoneCredential(credential);
            if (mounted)
              setState(() => _isLoading = false); // Stop loading on completion
          },
          verificationFailed: (FirebaseAuthException e) {
            print("Phone verification failed: ${e.message}");
            if (mounted) {
              setState(() => _isLoading = false); // Stop loading on failure
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Phone verification failed: ${e.code}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            print("OTP code sent. Verification ID: $verificationId");
            if (mounted) {
              setState(
                () => _isLoading = false,
              ); // Stop loading, navigate to OTP screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => OTPScreen(
                        verificationId: verificationId,
                        phoneNumber: phoneNumberWithCountryCode,
                        resendToken: resendToken, // Pass the resend token
                      ),
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print(
              "OTP auto-retrieval timed out. Verification ID: $verificationId",
            );
            // Optionally handle timeout, maybe allow resend?
            if (mounted)
              setState(() => _isLoading = false); // Stop loading on timeout
          },
        );
    // Note: _isLoading might be set back to false within the callbacks
    // If verifyPhoneNumber itself throws an exception (before callbacks),
    // the listener on authProvider state should catch the error state.
  }

  @override
  Widget build(BuildContext context) {
    // Listener for loading state and errors
    ref.listen<AuthState>(authProvider, (_, next) {
      if (mounted) {
        setState(() {
          _isLoading = next.maybeWhen(loading: () => true, orElse: () => false);
        });
        next.maybeWhen(
          error: (message) {
            // Ensure loading is stopped if an error occurs during loading
            if (_isLoading) setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
          orElse: () {},
        );
      }
    });

    // Get potential error message for display (only when not loading)
    final authState = ref.watch(authProvider);
    String? displayErrorMessage = widget.errorMessage;
    if (!_isLoading) {
      authState.maybeWhen(
        error: (message) => displayErrorMessage = message,
        orElse: () {},
      );
    }

    // Define common button style
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary, // Teal blue
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2, // Add some elevation
    );

    final ButtonStyle googleButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white, // Google button specific style
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
    );

    return Scaffold(
      appBar: AppBar(
        // No title
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Match background
        elevation: 0, // No shadow
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [Tab(text: 'EMAIL'), Tab(text: 'PHONE')],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                // Constrain height of TabBarView if needed, or let it expand
                height: 300, // Adjust height as needed
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Email Tab ---
                    _buildEmailLoginForm(buttonStyle),
                    // --- Phone Tab ---
                    _buildPhoneLoginForm(buttonStyle),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Common Login Options ---
              Row(
                // Divider OR
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
                  style: googleButtonStyle, // Apply specific style
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
                            ref.read(authProvider.notifier).signInAnonymously(),
                child: const Text('Continue Anonymously'),
              ),
              const SizedBox(height: 20),

              // Sign Up Link (Common for both tabs)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
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

              // Display Error Message
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
    );
  }

  // --- Helper to build Email Login Form ---
  Widget _buildEmailLoginForm(ButtonStyle buttonStyle) {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 24),
          _isLoading &&
                  _tabController.index ==
                      0 // Show loader only if email tab is active and loading
              ? const CircularProgressIndicator()
              : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmail,
                  style: buttonStyle, // Apply common style
                  child: const Text('Login'),
                ),
              ),
        ],
      ),
    );
  }

  // --- Helper to build Phone Login Form ---
  Widget _buildPhoneLoginForm(ButtonStyle buttonStyle) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              hintText: '+91 XXXXX XXXXX', // Example hint
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Allow only digits
            ],
            maxLength: 10, // Limit to 10 digits
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (value.length != 10) {
                return 'Mobile number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _isLoading &&
                  _tabController.index ==
                      1 // Show loader only if phone tab is active and loading
              ? const CircularProgressIndicator()
              : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _loginWithPhone, // Connect to placeholder
                  style: buttonStyle, // Apply common style
                  child: const Text('Continue with Phone'),
                ),
              ),
        ],
      ),
    );
  }
}
