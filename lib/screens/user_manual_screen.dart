import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({Key? key}) : super(key: key);

  // Helper function to create consistent padding and structure for sections
  Widget _buildSection({
    required String title,
    required String description,
    String? imagePath, // Optional image path
    double imageScale = 1.0, // Optional scale for the image
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal, // Match app theme
            ),
          ),
          const SizedBox(height: 8.0),
          Text(description, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (imagePath != null) ...[
            const SizedBox(height: 12.0),
            Center(
              child: Image.asset(
                imagePath,
                scale: imageScale,
                errorBuilder: (context, error, stackTrace) {
                  // Display a placeholder if the image fails to load
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.grey[200],
                    child: Text(
                      'Image not found:\n$imagePath',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12.0),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        backgroundColor: Colors.teal, // Match app theme
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: '1. Getting Started: Login & Sign Up',
            description:
                'Welcome to Habit Tracker! To begin, you need to log in or create an account.',
            imagePath: 'assets/manual/login_screen.jpeg',
          ),
          _buildSection(
            title: '1.1 Creating an Account',
            description:
                'If you\'re new, tap the "Sign Up" link (highlighted below) to create your account using your email and a password.',
            imagePath: 'assets/manual/signup_link.jpeg',
          ),
          _buildSection(
            title: '1.2 Sign Up Screen',
            description:
                'Fill in your details on the Sign Up screen and tap the "Sign Up" button.',
            imagePath: 'assets/manual/signup_screen.jpeg',
          ),
          _buildSection(
            title: '1.3 Forgot Password?',
            description:
                'If you\'ve forgotten your password, tap the "Forgot Password?" link on the login screen.',
            imagePath: 'assets/manual/forgot_password_link.jpeg',
          ),
          _buildSection(
            title: '1.4 Resetting Your Password',
            description:
                'Enter your registered email address, and we\'ll send you instructions to reset your password.',
            imagePath: 'assets/manual/forgot_password_screen.jpeg',
          ),
          _buildSection(
            title: '2. The Home Screen: Your Dashboard',
            description:
                'After logging in, you\'ll land on the Home Screen. It has three main tabs: Rewards, Habits, and Graphs.',
            imagePath: 'assets/manual/home_screen_habits_tab.jpeg',
          ),
          _buildSection(
            title: '3. Managing Habits (Habits Tab)',
            description:
                'This is where you track your daily progress. You can add new habits, mark existing ones as done, skipped, or failed, and view your streaks.',
          ),
          _buildSection(
            title: '3.1 Adding a New Habit',
            description:
                'Tap the pink "+" button at the bottom right of the Habits tab to add a new habit.',
            imagePath: 'assets/manual/add_habit_button.jpeg',
          ),
          _buildSection(
            title: '3.2 Add/Edit Habit Screen',
            description:
                'Define your habit\'s name, description, reasons, start date, schedule, and reminders here. Tap "Save Habit" when done.',
            imagePath: 'assets/manual/add_edit_habit_screen.jpeg',
          ),
          _buildSection(
            title: '3.3 Tracking Daily Progress',
            description:
                'On each habit card for the current day, tap "Done", "Skip", or "Fail" to record its status. Completing habits earns you points!',
            imagePath: 'assets/manual/habit_card_actions.jpeg',
          ),
          _buildSection(
            title: '3.4 Viewing Habit Details',
            description:
                'Tap anywhere on a habit card (except the action buttons) to see its detailed history, stats, notes, and reasons.',
            imagePath: 'assets/manual/habit_detail_screen.jpeg',
          ),
          _buildSection(
            title: '4. Visualizing Progress (Graphs Tab)',
            description:
                'The Graphs tab provides visual summaries of your habit consistency and progress over time. Tap on a graph card to see more detailed statistics for that habit.',
            imagePath: 'assets/manual/graphs_tab.jpeg',
          ),
          _buildSection(
            title: '5. Rewards & Achievements (Rewards Tab)',
            description:
                'Earn points for completing habits and unlock achievements! Use your points to claim custom rewards you define.',
            imagePath: 'assets/manual/rewards_tab.jpeg',
          ),
          _buildSection(
            title: '5.1 Adding Custom Rewards',
            description:
                'Tap the "+" icon next to the "Rewards" title to create your own rewards with a name, description, and point cost.',
            imagePath: 'assets/manual/add_reward_button.jpeg',
          ),
          _buildSection(
            title: '5.2 Claiming Rewards',
            description:
                'If you have enough points, the "Claim" button next to a reward will be active. Tap it to spend your points and claim the reward.',
            imagePath: 'assets/manual/claim_reward_button.jpeg',
          ),
          _buildSection(
            title: '5.3 Achievements',
            description:
                'As you build streaks and maintain consistency, you\'ll automatically unlock achievements, which are displayed in this section.',
            imagePath: 'assets/manual/achievements_section.jpeg',
          ),
          _buildSection(
            title: '6. App Menu (Drawer)',
            description:
                'Tap the hamburger icon (☰) in the top-left corner of the Home Screen to open the app menu (Drawer). Here you can access Premium features, Import/Export data, About info, and Logout.',
            imagePath: 'assets/manual/drawer_menu.jpeg',
          ),
          _buildSection(
            title: '6.1 Accessing This Manual',
            description:
                'You found it! The "User Manual" link is located in the Drawer menu.',
            // Placeholder for the missing image - add 'assets/manual/user_manual_link.jpeg' later if available
            imagePath:
                null, // 'assets/manual/user_manual_link.jpeg' - Add when available
          ),
          const SizedBox(height: 20), // Add some padding at the end
        ],
      ),
    );
  }
}
