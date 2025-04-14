import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Teal

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        backgroundColor: primaryColor, // Use primary color for AppBar
        foregroundColor: Colors.white,
        elevation: 0, // Flat AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // Premium Badge/Icon Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1), // Light teal background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined, // Premium Icon
                    size: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upgrade to Premium',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock Your Full Potential',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Comparison Section
            _buildComparisonSection(
              context,
              primaryColor,
            ), // Call helper method
            const SizedBox(height: 30),

            // Pricing Section
            Center(
              // Center the pricing info
              child: Column(
                children: [
                  Text(
                    '₹515.43',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One-Time Payment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Space before button
            // CTA Button
            ElevatedButton(
              onPressed: () {
                // TODO: Implement payment logic
                print('Go Premium button tapped!');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment integration not implemented yet.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'GO PREMIUM',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Secure one-time payment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Comparison Section Widget ---
  // Moved inside the class
  Widget _buildComparisonSection(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Free Version:',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildFeatureTile(
          icon: Icons.track_changes,
          title: 'Track up to five habits',
          subtitle: '',
          color: Colors.grey,
        ),
        _buildFeatureTile(
          icon: Icons.card_giftcard,
          title: 'Add three rewards',
          subtitle: '',
          color: Colors.grey,
        ),
        _buildFeatureTile(
          icon: Icons.adjust,
          title: 'Add five targets',
          subtitle: '',
          color: Colors.grey,
        ),
        _buildFeatureTile(
          icon: Icons.notifications_active_outlined,
          title: 'Powerful Reminders',
          subtitle: '',
          color: Colors.grey,
        ),
        _buildFeatureTile(
          icon: Icons.chat_bubble_outline,
          title: 'Motivational Quotes',
          subtitle: '',
          color: Colors.grey,
        ),
        _buildFeatureTile(
          icon: Icons.widgets_outlined,
          title: 'Beautiful widgets',
          subtitle: '',
          color: Colors.grey,
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        Text(
          'Premium Version Unlocks:',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureTile(
          icon: Icons.card_giftcard,
          title: 'Add unlimited rewards',
          subtitle: 'Motivate yourself without limits.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.adjust,
          title: 'Add unlimited targets',
          subtitle: 'Challenge yourself further.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.track_changes,
          title: 'Track unlimited habits',
          subtitle: 'Monitor all your goals.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.edit_calendar_outlined,
          title: 'Track habits with daily values',
          subtitle: '(e.g., water intake, study time)',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.cloud_upload_outlined,
          title: 'Automatic backup',
          subtitle: 'To external storage providers.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.pie_chart_outline,
          title: 'Advanced widgets',
          subtitle: 'Pie charts and progress charts.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.ios_share,
          title: 'Export your data to CSV',
          subtitle: 'Keep your data accessible.',
          color: primaryColor,
        ),
        _buildFeatureTile(
          icon: Icons.pin_outlined,
          title: 'Secure your data with PIN lock',
          subtitle: 'Added privacy.',
          color: primaryColor,
        ),
      ],
    );
  }

  // Helper widget for feature list items
  // Moved inside the class
  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Only show subtitle if it's not empty
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
