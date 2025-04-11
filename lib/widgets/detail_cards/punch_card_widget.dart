import 'dart:ui'; // Import needed for TextDirection
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../models/habit.dart';
import '../../utils/habit_utils.dart'; // Import the calculation utility

class PunchCardWidget extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;

  const PunchCardWidget({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    final punchCardData = calculatePunchCardData(habit, fromDate, toDate);

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Punch Card',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Use AspectRatio to maintain a reasonable shape for the painter
            AspectRatio(
              aspectRatio: 2.5, // Adjust aspect ratio as needed
              child:
                  punchCardData.maxCount == 0
                      ? const Center(
                        child: Text('No completed habits in this period.'),
                      )
                      : CustomPaint(
                        painter: _PunchCardPainter(
                          data: punchCardData.monthlyWeekdayCounts,
                          maxCount: punchCardData.maxCount,
                        ),
                        child: Container(), // Painter needs a child
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the Punch Card
class _PunchCardPainter extends CustomPainter {
  final Map<int, Map<int, int>> data; // Month -> DayOfWeek -> Count
  final int maxCount;
  final List<String> _monthLabels =
      DateFormat.MMMM().dateSymbols.SHORTMONTHS; // Jan, Feb, ...
  final List<String> _dayLabels = [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ]; // Match image

  _PunchCardPainter({required this.data, required this.maxCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (maxCount <= 0) return; // Nothing to draw

    final double horizontalPadding = 30.0;
    final double verticalPadding = 20.0;
    final double gridWidth = size.width - 2 * horizontalPadding;
    final double gridHeight = size.height - 2 * verticalPadding;

    final double cellWidth = gridWidth / 12; // 12 months
    final double cellHeight = gridHeight / 7; // 7 days

    final double maxRadius =
        min(cellWidth, cellHeight) / 2.5; // Max radius for dots

    final textStyle = const TextStyle(color: Colors.grey, fontSize: 10);
    final paint = Paint()..color = Colors.teal; // Dot color

    // Draw Month Labels (Bottom)
    for (int i = 0; i < 12; i++) {
      final dx = horizontalPadding + (i + 0.5) * cellWidth;
      final dy = size.height - verticalPadding / 2;
      _drawText(canvas, _monthLabels[i], dx, dy, textStyle, alignCenter: true);
    }

    // Draw Day Labels (Right)
    for (int i = 0; i < 7; i++) {
      final dx = size.width - horizontalPadding / 2;
      // Draw days Sunday (index 0) to Saturday (index 6) from bottom to top
      final dy = verticalPadding + ((6 - i) + 0.5) * cellHeight;
      _drawText(canvas, _dayLabels[i], dx, dy, textStyle, alignCenter: true);
    }

    // Draw Dots
    for (int month = 1; month <= 12; month++) {
      if (data.containsKey(month)) {
        for (int weekday = 1; weekday <= 7; weekday++) {
          // DateTime: 1=Mon, 7=Sun
          if (data[month]!.containsKey(weekday)) {
            final count = data[month]![weekday]!;
            final radius = (count / maxCount) * maxRadius;

            // Adjust weekday for drawing (0=Sun, 6=Sat) from bottom up
            final dayIndex =
                (weekday % 7); // Convert Mon=1..Sun=7 to Sun=0..Sat=6
            final drawYIndex = 6 - dayIndex; // Invert Y-axis

            final dx = horizontalPadding + (month - 1 + 0.5) * cellWidth;
            final dy = verticalPadding + (drawYIndex + 0.5) * cellHeight;

            if (radius > 0.5) {
              // Only draw if radius is significant
              // Vary opacity based on count? Or just size? Let's use size.
              // paint.color = Colors.teal.withOpacity(max(0.2, count / maxCount));
              canvas.drawCircle(Offset(dx, dy), radius, paint);
            }
          }
        }
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style, {
    bool alignCenter = false,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      //textDirection: TextDirection.ltr, // Correct usage
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
    );
    textPainter.layout(minWidth: 0, maxWidth: 50); // Provide max width
    final offset =
        alignCenter
            ? Offset(x - textPainter.width / 2, y - textPainter.height / 2)
            : Offset(x, y - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PunchCardPainter oldDelegate) {
    // Repaint if data or maxCount changes
    return oldDelegate.data != data || oldDelegate.maxCount != maxCount;
  }
}
