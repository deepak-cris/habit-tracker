import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../utils/habit_utils.dart'; // Import the calculation utility

class HabitStrengthCard extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;

  const HabitStrengthCard({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the strength percentage
    final double strengthPercent = calculateHabitStrength(
      habit,
      fromDate,
      toDate,
    );
    // Convert percentage (0-100) to progress value (0.0-1.0)
    final double progressValue = strengthPercent / 100.0;

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Habit Strength',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 120, // Size of the circular indicator
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 10, // Thickness of the progress ring
                      backgroundColor:
                          Colors.grey.shade300, // Background color of the ring
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.teal,
                      ), // Progress color
                    ),
                    Center(
                      child: Text(
                        // Display percentage with one decimal place
                        '${strengthPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8), // Add some spacing at the bottom
          ],
        ),
      ),
    );
  }
}
