import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/quotes.dart';
import '../auth/auth_notifier.dart'; // Import auth_notifier to access splashFinishedProvider

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _quote = '';
  // Removed splashDurationSeconds as timer is removed

  @override
  void initState() {
    super.initState();

    _quote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

    // Use a fixed duration for animations, independent of navigation timer
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Animation duration changed to 5
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller)..addListener(() {
      setState(() {});
    });

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _controller.forward().whenComplete(() {
      // When animation completes, update the splash finished provider
      // This replaces the Timer logic
      if (mounted) {
        print(
          "Splash Screen: Animation finished, setting splashFinishedProvider to true.",
        );
        ref.read(splashFinishedProvider.notifier).state = true;
      }
    }); // Start the animations and set callback
  }

  // REMOVED _navigateToLogin method

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final Color darkTeal = Colors.teal.shade900;
    // final Color lightTeal = Colors.teal.shade400;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          ),
          /* ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  darkTeal.withOpacity(0.8),
                  lightTeal.withOpacity(0.3),
                  darkTeal.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(color: darkTeal.withOpacity(0.8)),
          ),*/
          Positioned(
            bottom: 50.0,
            left: 20.0,
            right: 20.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      _quote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8.0,
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
