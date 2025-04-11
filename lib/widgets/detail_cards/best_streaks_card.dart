import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../utils/habit_utils.dart'; // Import the calculation utility

class BestStreaksCard extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;

  const BestStreaksCard({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    final StreakInfo bestStreak = calculateBestStreakInRange(
      habit,
      fromDate,
      toDate,
    );
    final DateFormat formatter = DateFormat(
      'dd MMM, yyyy',
    ); // Format like "08 Apr, 2025"

    String streakText;
    if (bestStreak.length > 0 &&
        bestStreak.startDate != null &&
        bestStreak.endDate != null) {
      streakText =
          '${formatter.format(bestStreak.startDate!)}   ${bestStreak.length}   ${formatter.format(bestStreak.endDate!)}';
    } else if (bestStreak.length > 0 && bestStreak.startDate != null) {
      // Case where streak might end exactly on toDate or start/end same day
      streakText =
          '${formatter.format(bestStreak.startDate!)}   ${bestStreak.length}   ${formatter.format(bestStreak.startDate!)}';
    } else {
      streakText = 'No streaks found in this period.';
    }

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Streaks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (bestStreak.length > 0 && bestStreak.startDate != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Start Date
                  Column(
                    children: [
                      Text(
                        formatter.format(bestStreak.startDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'Start',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  // Streak Length (Large)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bestStreak.length}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bestStreak.length == 1 ? 'day' : 'days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  // End Date
                  Column(
                    children: [
                      Text(
                        // Use start date if end date is null (streak of 1 or ends today)
                        formatter.format(
                          bestStreak.endDate ?? bestStreak.startDate!,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        'End',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  streakText, // "No streaks found..."
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 8), // Add some spacing at the bottom
          ],
        ),
      ),
    );
  }
}
