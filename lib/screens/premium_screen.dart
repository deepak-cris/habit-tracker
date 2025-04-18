import 'package:flutter/material.dart';
import 'package:upi_pay/upi_pay.dart'; // Import upi_pay
import 'package:uuid/uuid.dart'; // Import UUID for transaction ID

// Convert to StatefulWidget
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final Uuid _uuid = const Uuid(); // UUID instance
  final _upiPayPlugin = UpiPay(); // upi_pay instance
  List<ApplicationMeta>? _apps; // To store installed UPI apps

  @override
  void initState() {
    super.initState();
    // Get installed UPI apps when the screen initializes
    // Use statusType: all as per example, might help detection
    _upiPayPlugin
        .getInstalledUpiApplications(
          statusType: UpiApplicationDiscoveryAppStatusType.all,
        )
        .then((value) {
          setState(() {
            _apps = value;
          });
        })
        .catchError((e) {
          print('Error fetching UPI apps: $e');
          _apps = []; // Initialize as empty list on error
          setState(() {}); // Update state even on error
        });
  }

  // --- UPI Payment Logic ---

  Future<void> _startUpiPayment(ApplicationMeta app) async {
    // Payment Details
    const String receiverUpiId = 'deepakhbti13@ybl';
    const String receiverName = 'Habit Tracker App';
    // upi_pay uses transactionRef, not transactionId
    final String transactionRef = _uuid.v4();
    const String transactionNote = 'Habit Tracker Premium Purchase';
    //const double amount = 515.43; // Amount from UI
    const double amount = 1.00;

    // Show loading or disable button if needed
    // setState(() => _isProcessing = true); // Example

    try {
      final UpiTransactionResponse response = await _upiPayPlugin
          .initiateTransaction(
            amount: amount.toStringAsFixed(
              2,
            ), // Amount as String with 2 decimal places
            app: app.upiApplication, // The selected UPI app's enum value
            receiverName: receiverName,
            receiverUpiAddress: receiverUpiId,
            transactionRef: transactionRef,
            transactionNote: transactionNote,
            // merchantCode: 'YOUR_MERCHANT_CODE', // Optional
          );

      // Handle the response
      _handleUpiResponse(response);
    } catch (e) {
      print('Error starting UPI transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating UPI payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Re-enable button or hide loading
      // if (mounted) setState(() => _isProcessing = false); // Example
    }
  }

  void _handleUpiResponse(UpiTransactionResponse? response) {
    if (response == null) {
      print('UPI Response was null (likely cancelled)');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction cancelled.')));
      }
      return;
    }

    print('UPI Response: ${response.toString()}'); // Log raw response

    String? txnId = response.txnId;
    UpiTransactionStatus? status = response.status; // Get the enum status
    String? txnRef = response.txnRef;

    String message;
    Color backgroundColor = Colors.grey;

    // Compare directly with the enum values
    if (status == UpiTransactionStatus.success) {
      message = 'Payment Successful! Transaction ID: $txnId';
      backgroundColor = Colors.green;
      // IMPORTANT: Verify transaction server-side here using txnRef before granting premium
      print('UPI Success: TxnID=$txnId, Ref=$txnRef');
      // TODO: Add logic to update user premium status (ideally after server verification)
    } else if (status == UpiTransactionStatus.submitted) {
      message = 'Payment Submitted. Transaction ID: $txnId';
      backgroundColor = Colors.orange;
      // Still needs server verification.
      print('UPI Submitted: TxnID=$txnId, Ref=$txnRef');
    } else if (status == UpiTransactionStatus.failure) {
      message = 'Payment Failed. Transaction ID: $txnId';
      backgroundColor = Colors.red;
      print('UPI Failure: TxnID=$txnId, Ref=$txnRef');
    } else {
      // PENDING or unknown
      message =
          'Payment Pending/Unknown. Status: ${status?.name ?? 'Unknown'}'; // Use enum name
      backgroundColor = Colors.grey;
      print(
        'UPI Pending/Unknown: TxnID=$txnId, Ref=$txnRef, Status=${status?.name}',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  // --- Method to show Modal Bottom Sheet with UPI Apps in a Grid ---
  void _showUpiAppSheet() {
    // Ensure apps list is loaded and not empty before showing sheet
    if (_apps == null || _apps!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI apps are still loading or none were found.'),
        ),
      );
      return;
    }

    // Sort apps alphabetically for consistent order
    _apps!.sort(
      (a, b) => a.upiApplication.getAppName().toLowerCase().compareTo(
        b.upiApplication.getAppName().toLowerCase(),
      ),
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            // Use Column for title + grid
            mainAxisSize: MainAxisSize.min, // Fit content height
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Select UPI App to Pay',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              GridView.count(
                crossAxisCount: 4, // Number of columns in the grid
                shrinkWrap:
                    true, // Important to make GridView work inside Column
                physics:
                    const NeverScrollableScrollPhysics(), // Disable grid scrolling
                padding: const EdgeInsets.all(8.0),
                children:
                    _apps!
                        .map(
                          (app) => InkWell(
                            key: ObjectKey(
                              app.upiApplication,
                            ), // Use unique key
                            onTap: () {
                              Navigator.of(context).pop(); // Close the sheet
                              _startUpiPayment(app); // Initiate payment
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                app.iconImage(48), // App icon
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  alignment: Alignment.center,
                                  child: Text(
                                    app.upiApplication.getAppName(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines:
                                        1, // Prevent long names wrapping badly
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Handle overflow
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16), // Add some padding at the bottom
            ],
          ),
        );
      },
    );
  }

  // --- UI Helper to build the main payment button ---
  Widget _buildPaymentButton() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Show loading if apps are still being fetched
    if (_apps == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show message if no apps found
    else if (_apps!.isEmpty) {
      return Center(
        child: Text(
          'No UPI apps found to complete payment.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      );
    }
    // Show the "Choose App" button if apps are available
    else {
      return ElevatedButton(
        onPressed: _showUpiAppSheet, // This will open the app selection sheet
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
          'CHOOSE UPI APP & PAY',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  // --- Helper Methods (Moved inside State class) ---

  // --- Comparison Section Widget ---
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

  // --- Build Method ---
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
            // --- UPI Payment Button ---
            _buildPaymentButton(), // Use the helper to show apps/button

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
  } // End build method
} // End _PremiumScreenState class
