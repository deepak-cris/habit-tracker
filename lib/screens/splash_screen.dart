import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/quotes.dart'; // Import the quotes
import 'login_screen.dart'; // Import the login screen
import '../auth/auth_notifier.dart'; // Import auth provider
import '../auth/auth_state.dart'; // Import auth state
import 'home_screen.dart'; // Import home screen

class SplashScreen extends ConsumerStatefulWidget {
  // Use ConsumerStatefulWidget
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation; // New animation for text fade-in
  String _quote = '';
  static const int splashDurationSeconds = 4;

  @override
  void initState() {
    super.initState();

    // Select a random quote
    _quote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

    // Setup animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: splashDurationSeconds),
      vsync: this,
    );

    // Setup progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller)..addListener(() {
      setState(() {}); // Rebuild to update progress bar
    });

    // Setup scale animation (e.g., zoom from 1.0 to 1.1 scale)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Setup fade animation (fade in during the first second)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Fade in during the first 25% of the splash duration
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _controller.forward().whenComplete(() {
      // When animation completes, update the splash finished provider
      if (mounted) {
        print(
          "Splash Screen: Animation finished, setting splashFinishedProvider to true.",
        );
        ref.read(splashFinishedProvider.notifier).state = true;
      }
    }); // Start the animations and set callback

    // REMOVED Timer and _navigateToLogin method
  }

  // REMOVED _navigateToLogin method

  @override
  void dispose() {
    _controller.dispose(); // Dispose animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the teal gradient colors
    final Color darkTeal = Colors.teal.shade900;
    final Color lightTeal =
        Colors.teal.shade400; // Adjusted for better visibility

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with ScaleTransition
          ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          ),
          // Dark + Lighting Effect Overlay using ShaderMask
          ShaderMask(
            shaderCallback: (Rect bounds) {
              // Gradient from dark teal at top/bottom to lighter teal in middle
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  darkTeal.withOpacity(0.8), // Darker overlay at top
                  lightTeal.withOpacity(0.3), // Lighter overlay in middle
                  darkTeal.withOpacity(0.8), // Darker overlay at bottom
                ],
                stops: const [0.0, 0.5, 1.0], // Adjust stops for effect
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop, // Apply gradient over the image
            child: Container(color: darkTeal.withOpacity(0.8)),
          ),

          // Content Column (Quote and Progress Bar)
          Positioned(
            bottom: 50.0, // Position content towards the bottom
            left: 20.0,
            right: 20.0,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum space
              children: [
                // Motivational Quote with Fade Transition and improved styling
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    // Optional: Add a subtle background blur for readability
                    // decoration: BoxDecoration(
                    //   color: Colors.black.withOpacity(0.2),
                    //   borderRadius: BorderRadius.circular(8.0),
                    // ),
                    child: Text(
                      _quote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0, // Slightly larger font
                        color: Colors.white,
                        fontWeight: FontWeight.w600, // Bolder
                        fontStyle: FontStyle.italic, // Italicize
                        shadows: [
                          // Add shadow for better readability
                          Shadow(
                            blurRadius: 10.0, // Increase blur
                            color: Colors.black.withOpacity(
                              0.7,
                            ), // Darker shadow
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30.0),

                // Animated Progress Bar
                ClipRRect(
                  // Round the corners
                  borderRadius: BorderRadius.circular(10.0),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value, // Use progress animation
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8.0, // Make the bar thicker
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
