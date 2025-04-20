import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get app version (requires package_info_plus - add later if needed)
    // String appVersion = '1.0.0'; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Habit Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        // Use ListView for potentially longer content
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(
            child: Icon(
              Icons.track_changes, // Or your app logo icon
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Habit Tracker',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Version 1.0.0', // Placeholder version
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Build Better Habits, Achieve Your Goals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'This app helps you build and maintain positive habits, track your progress visually, and stay motivated on your journey of self-improvement. Consistency is key, and we\'re here to support you every step of the way.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ), // Improved line spacing
          ),
          const SizedBox(height: 24),

          Text(
            // Added developer credit
            'Developed by Deepak',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Add more info like contact, website, licenses if needed
        ],
      ),
    );
  }
}
