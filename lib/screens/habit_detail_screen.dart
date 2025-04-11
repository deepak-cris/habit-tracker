import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// We are building manually, so TableCalendar is not needed here
// import 'package:table_calendar/table_calendar.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import 'home_screen.dart'; // Import habitProvider (needed for potential actions)

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime? _selectedDay = DateTime.now(); // Keep track of selected day
  final List<String> _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  // Define the range for the calendar list
  late DateTime _firstMonth;
  late DateTime _lastMonth;
  late int _totalMonths;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    // Determine calendar range
    _firstMonth = DateTime.utc(
      widget.habit.startDate.year,
      widget.habit.startDate.month,
    );
    // Example: Show up to 1 year from now + current month
    _lastMonth = DateTime.utc(DateTime.now().year + 1, DateTime.now().month);
    _totalMonths =
        (_lastMonth.year - _firstMonth.year) * 12 +
        _lastMonth.month -
        _firstMonth.month +
        1;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1, // Start on CALENDAR tab
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.habit.name, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () {
                /* TODO: Edit action */
              },
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: Colors.white),
              onPressed: () {
                /* TODO: Archive/Delete action */
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined, color: Colors.white),
              onPressed: () {
                /* TODO: Stats action */
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'TARGETS'),
              Tab(text: 'CALENDAR'),
              Tab(text: 'DETAILS'),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildTargetsTab(widget.habit),
            _buildCalendarTab(widget.habit), // Uses ListView.builder
            _buildDetailsTab(widget.habit), // Corrected Details Tab call
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            /* TODO: FAB action */
          },
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // --- Tab Builder Methods ---

  Widget _buildTargetsTab(Habit habit) {
    // Placeholder (remains the same)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Text(habit.targetStreak.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.19, // Placeholder
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  minHeight: 10,
                ),
              ),
              const SizedBox(width: 10),
              const Text('19%'), // Placeholder
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          const Expanded(
            child: Center(child: Text('Targets Tab Content (TODO)')),
          ),
        ],
      ),
    );
  }

  // Builds the vertically scrolling calendar using ListView.builder
  Widget _buildCalendarTab(Habit habit) {
    return ListView.builder(
      itemCount: _totalMonths,
      itemBuilder: (context, index) {
        final month = DateTime.utc(_firstMonth.year, _firstMonth.month + index);
        return _buildMonthView(habit, month.year, month.month);
      },
    );
  }

  // Builds the view for a single month
  Widget _buildMonthView(Habit habit, int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime.utc(year, month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7; // 0=Sun, 6=Sat

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Text(
              DateFormat.yMMMM().format(firstDayOfMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            ),
            // Calculate total cells needed, including leading/trailing empty cells
            itemCount: (daysInMonth + firstWeekdayOfMonth + 6) ~/ 7 * 7,
            itemBuilder: (context, index) {
              final dayOffset = index - firstWeekdayOfMonth;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return Container(); // Empty cell outside the month
              }
              final day = firstDayOfMonth.add(Duration(days: dayOffset));
              return _buildCalendarDayCell(habit, day);
            },
          ),
          const Divider(height: 20, thickness: 1),
        ],
      ),
    );
  }

  // Builds a single day cell for the GridView, including connector logic
  Widget _buildCalendarDayCell(Habit habit, DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final isToday = DateUtils.isSameDay(
      normalizedDay,
      DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ),
    );
    final isSelected =
        _selectedDay != null &&
        DateUtils.isSameDay(normalizedDay, _selectedDay);
    final currentStatus = habit.getStatusForDate(normalizedDay);

    // Check previous and next day status for connectors
    final prevDay = normalizedDay.subtract(const Duration(days: 1));
    final nextDay = normalizedDay.add(const Duration(days: 1));
    final prevStatus = habit.getStatusForDate(prevDay);
    final nextStatus = habit.getStatusForDate(nextDay);

    bool showLeftConnector =
        currentStatus == HabitStatus.done &&
        prevStatus == HabitStatus.done &&
        day.weekday != DateTime.sunday;
    bool showRightConnector =
        currentStatus == HabitStatus.done &&
        nextStatus == HabitStatus.done &&
        day.weekday != DateTime.saturday;

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
        bgColor = isToday ? Colors.blue.shade100 : Colors.white;
        textColor = isToday ? Colors.blueAccent : Colors.black87;
        break;
    }

    // Build the core day cell content
    Widget dayContent = Container(
      margin: const EdgeInsets.all(1.0),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color:
            isSelected
                ? Colors.blueAccent.withOpacity(0.7)
                : bgColor, // Selection has higher priority
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontSize: 12,
          ),
        ),
      ),
    );

    // Wrap with CustomPaint to draw connectors
    return CustomPaint(
      painter: _DayConnectorPainter(
        drawLeft: showLeftConnector,
        drawRight: showRightConnector,
      ),
      child: InkWell(
        // Keep InkWell for tap effect and selection
        onTap: () {
          setState(() {
            _selectedDay = normalizedDay;
          });
          // TODO: Show notes/status for the selected day?
        },
        customBorder: const CircleBorder(),
        child: dayContent,
      ),
    );
  }

  // Corrected _buildDetailsTab implementation
  Widget _buildDetailsTab(Habit habit) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      // Add background color consistent with Add/Edit screen
      color: Colors.grey[100],
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard(
            title: 'Description',
            content: Text(
              habit.description ?? 'No description provided.',
              style: textTheme.bodyMedium,
            ),
          ),
          _buildDetailCard(
            title: 'Target Streak',
            content: Text(
              '${habit.targetStreak} days',
              style: textTheme.bodyMedium,
            ),
          ),
          _buildDetailCard(
            title: 'Start Date',
            content: Text(
              DateFormat.yMMMd().format(habit.startDate),
              style: textTheme.bodyMedium,
            ),
          ),
          _buildDetailCard(
            title: 'Schedule',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type: ${habit.scheduleType}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Days: ${_getSelectedDaysString(habit.selectedDays)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _buildDetailCard(
            title: 'Reasons',
            content:
                habit.reasons.isEmpty
                    ? Text(
                      'No reasons added.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                    : Column(
                      // Display reasons line by line
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          habit.reasons
                              .map(
                                (reason) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    '• $reason',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
          // TODO: Add more sections like stats, edit/delete buttons etc.
        ],
      ),
    );
  }

  // Helper widget for styled detail cards
  Widget _buildDetailCard({required String title, required Widget content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1.0, // Subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            content,
          ],
        ),
      ),
    );
  }

  String _getSelectedDaysString(List<bool> selectedDays) {
    List<String> days = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        days.add(_dayNames[i]);
      }
    }
    return days.isNotEmpty ? days.join(', ') : 'None';
  }
} // End of _HabitDetailScreenState class

// Custom Painter for the connector line (Keep this definition)
class _DayConnectorPainter extends CustomPainter {
  final bool drawLeft;
  final bool drawRight;

  _DayConnectorPainter({this.drawLeft = false, this.drawRight = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawLeft && !drawRight) return;

    final paint =
        Paint()
          ..color = Colors.green.shade300
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final centerX = size.width / 2;

    if (drawLeft) {
      canvas.drawLine(Offset(0, centerY), Offset(centerX, centerY), paint);
    }
    if (drawRight) {
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(size.width, centerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DayConnectorPainter oldDelegate) {
    // Removed covariant
    return oldDelegate.drawLeft != drawLeft ||
        oldDelegate.drawRight != drawRight;
  }
}
