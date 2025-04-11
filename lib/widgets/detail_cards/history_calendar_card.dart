import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../models/habit_status.dart';
import '../../utils/habit_utils.dart'; // For normalizeDate

class HistoryCalendarCard extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> _dayNames = const [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  const HistoryCalendarCard({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> monthWidgets = _buildMonthlyViews();

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (monthWidgets.isEmpty)
              const Center(child: Text('No history data for this period.'))
            else
              Column(
                children: monthWidgets,
              ), // Display the list of monthly views
          ],
        ),
      ),
    );
  }

  // Generates a list of widgets, each representing a month's calendar view
  List<Widget> _buildMonthlyViews() {
    List<Widget> widgets = [];
    DateTime currentMonthStart = DateTime.utc(fromDate.year, fromDate.month, 1);
    final lastMonth = DateTime.utc(toDate.year, toDate.month, 1);

    while (!currentMonthStart.isAfter(lastMonth)) {
      widgets.add(
        _buildMonthView(currentMonthStart.year, currentMonthStart.month),
      );
      // Move to the next month
      currentMonthStart = DateTime.utc(
        currentMonthStart.year,
        currentMonthStart.month + 1,
        1,
      );
    }
    return widgets;
  }

  // Builds the view for a single month
  Widget _buildMonthView(int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime.utc(year, month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7; // 0=Sun, 6=Sat

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Spacing between months
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              DateFormat.yMMMM().format(
                firstDayOfMonth,
              ), // Format like "April 2025"
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // Day Headers (Su, Mo, ...)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _dayNames
                    .map(
                      (name) => Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 4),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1, // Adjust aspect ratio for cell size
            ),
            itemCount:
                (daysInMonth + firstWeekdayOfMonth + 6) ~/
                7 *
                7, // Total cells needed
            itemBuilder: (context, index) {
              final dayOffset = index - firstWeekdayOfMonth;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return Container(); // Empty cell outside the month
              }
              final day = firstDayOfMonth.add(Duration(days: dayOffset));

              // Only build cells within the selected fromDate/toDate range
              if (day.isBefore(fromDate) || day.isAfter(toDate)) {
                return Container(); // Empty cell outside the selected range
              }
              return _buildCalendarDayCell(day);
            },
          ),
        ],
      ),
    );
  }

  // Builds a single day cell for the GridView
  Widget _buildCalendarDayCell(DateTime day) {
    final normalizedDay = normalizeDate(day); // Use helper from habit_utils
    final currentStatus = habit.getStatusForDate(normalizedDay);

    Color bgColor;
    Color textColor = Colors.black87;
    switch (currentStatus) {
      case HabitStatus.done:
        bgColor = Colors.green.shade300;
        textColor = Colors.white;
        break;
      case HabitStatus.fail:
        bgColor = Colors.red.shade300;
        textColor = Colors.white;
        break;
      case HabitStatus.skip:
        bgColor = Colors.orange.shade300;
        textColor = Colors.white;
        break;
      case HabitStatus.none:
      default:
        // Check if it's today (within the context of the app running)
        final now = DateTime.now();
        final normalizedToday = DateTime.utc(now.year, now.month, now.day);
        bool isToday = DateUtils.isSameDay(normalizedDay, normalizedToday);
        bgColor = isToday ? Colors.blue.shade100 : Colors.white;
        textColor = isToday ? Colors.blueAccent : Colors.black87;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(2.0), // Add spacing between cells
      decoration: BoxDecoration(
        color: bgColor,
        // Use rounded rectangle instead of circle to better fit numbers
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ), // Subtle border
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 11, // Slightly smaller font
          ),
        ),
      ),
    );
  }
}
