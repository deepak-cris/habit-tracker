import 'package:collection/collection.dart'; // Import collection package
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import 'home_screen.dart'; // Import habitProvider (needed for potential actions)
import 'add_edit_habit_screen.dart'; // Import AddEditHabitScreen
import 'habit_stats_screen.dart'; // Import HabitStatsScreen
import '../utils/habit_utils.dart'; // Import for normalizeDate

// Removed individual graph card imports

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

// Corrected class definition
class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime? _selectedDay = DateTime.now(); // Keep track of selected day
  final List<String> _dayNames = const [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

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
    // Watch the AsyncValue state of the habit provider
    final habitsAsync = ref.watch(habitProvider);

    // Use .when to handle loading, error, and data states
    return habitsAsync.when(
      loading:
          () => Scaffold(
            appBar: AppBar(
              title: Text(widget.habit.name), // Show initial name while loading
              backgroundColor: Colors.teal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stackTrace) => Scaffold(
            appBar: AppBar(
              title: Text(widget.habit.name), // Show initial name on error
              backgroundColor: Colors.teal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading habit details: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      data: (allHabits) {
        // Find the specific habit being detailed using firstWhereOrNull
        final Habit? liveHabit = allHabits.firstWhereOrNull(
          (h) => h.id == widget.habit.id,
        );

        // If the habit is not found in the live list (e.g., deleted)
        if (liveHabit == null) {
          // Optionally pop the screen automatically after a delay
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   if (mounted) { // Check if the widget is still in the tree
          //     Navigator.of(context).pop();
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text("Habit has been deleted.")),
          //     );
          //   }
          // });
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.habit.name), // Show original name
              backgroundColor: Colors.teal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text("This habit may have been deleted."),
            ),
          );
        }

        // If habit is found, build the main UI
        return DefaultTabController(
          initialIndex: 0, // Start on CALENDAR tab
          length: 3, // CALENDAR, GRAPHS, DETAILS
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                liveHabit.name,
                overflow: TextOverflow.ellipsis,
              ), // Use live habit name
              backgroundColor: Colors.teal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    // Navigate to AddEditHabitScreen for editing
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => AddEditHabitScreen(
                              habit: liveHabit, // Pass live habit
                            ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () {
                    // Show confirmation and delete habit
                    _showDeleteConfirmation(
                      context,
                      ref,
                      liveHabit.id, // Use live habit id
                    );
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'CALENDAR'),
                  Tab(text: 'GRAPHS'), // Added GRAPHS tab
                  Tab(text: 'DETAILS'),
                ],
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            body: TabBarView(
              children: [
                _buildCalendarTab(liveHabit), // Pass live habit
                _buildGraphsTab(liveHabit), // Added Graphs Tab View
                _buildDetailsTab(liveHabit), // Pass live habit
              ],
            ),
          ),
        );
      },
    );
  }

  // Confirmation Dialog for Deleting Habit
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String habitId,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Habit?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this habit?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                ref.read(habitProvider.notifier).deleteHabit(habitId);
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back from detail screen
              },
            ),
          ],
        );
      },
    );
  }

  // --- Tab Builder Methods ---

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
              // Only build cells on or after start date
              if (day.isBefore(normalizeDate(habit.startDate))) {
                return Container();
              }
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
    final normalizedDay = normalizeDate(day); // Use helper
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
        day.weekday != DateTime.sunday &&
        !prevDay.isBefore(
          normalizeDate(habit.startDate),
        ); // Don't connect before start
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
        color: bgColor, // Keep original background color based on status/today
        shape: BoxShape.circle,
        // Add border and shadow conditionally for selected day
        border:
            isSelected
                ? Border.all(
                  color: Colors.blueAccent.shade700,
                  width: 2.0,
                ) // Distinct border
                : null,
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ]
                : null, // No shadow if not selected
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            // Adjust text color based on selection AND background
            color:
                isSelected
                    ? (bgColor == Colors.white ||
                            bgColor == Colors.blue.shade100
                        ? Colors
                            .blueAccent
                            .shade700 // Contrast on light selected bg
                        : Colors.white) // White on dark selected bg
                    : textColor, // Original color if not selected
            fontSize: 12,
            fontWeight:
                isSelected
                    ? FontWeight.bold
                    : FontWeight.normal, // Make selected date bold
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
          // Show notes/status for the selected day via bottom sheet
          _showDayActions(context, habit, normalizedDay);
        },
        customBorder: const CircleBorder(),
        child: dayContent,
      ),
    );
  }

  // Show actions/note for the selected day (Refactored UI)
  void _showDayActions(BuildContext context, Habit habit, DateTime date) {
    // date is already normalized from _buildCalendarDayCell
    final currentStatus = habit.getStatusForDate(date);
    final currentNote = habit.getNoteForDate(date);
    final habitNotifier = ref.read(habitProvider.notifier);

    // Get normalized dates for validation
    final habitStartDate = normalizeDate(
      habit.startDate,
    ); // Ensure start date is normalized
    final today = normalizeDate(DateTime.now());
    // Determine if the selected date is valid for actions
    final bool isDateValid =
        !date.isAfter(today) && !date.isBefore(habitStartDate);

    showModalBottomSheet(
      context: context,
      // Add rounded corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        // Use Padding and Column for better control
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum height needed
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Centered Title
              Center(
                child: Text(
                  'Update Status for ${DateFormat.yMMMd().format(date)}', // More descriptive format
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Reduced spacing before note/buttons
              // Conditionally display info note if date is invalid
              if (!isDateValid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Marking allowed from start date to today only.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              // Action Buttons - Use Row with Expanded
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Space out buttons
                children: [
                  // Use Expanded to give buttons equal space
                  Expanded(
                    child: _buildActionButton(
                      Icons.check_circle,
                      'DONE',
                      Colors.green,
                      currentStatus == HabitStatus.done,
                      isDateValid, // Pass validation result
                      () {
                        habitNotifier.updateStatus(
                          habit.id,
                          date,
                          HabitStatus.done,
                        );
                        Navigator.pop(context); // Close bottom sheet
                      },
                    ),
                  ),
                  const SizedBox(width: 8), // Spacing between buttons
                  Expanded(
                    child: _buildActionButton(
                      Icons.cancel,
                      'FAIL',
                      Colors.red,
                      currentStatus == HabitStatus.fail,
                      isDateValid, // Pass validation result
                      () {
                        habitNotifier.updateStatus(
                          habit.id,
                          date,
                          HabitStatus.fail,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      Icons.skip_next,
                      'SKIP',
                      Colors.orange,
                      currentStatus == HabitStatus.skip,
                      isDateValid, // Pass validation result
                      () {
                        habitNotifier.updateStatus(
                          habit.id,
                          date,
                          HabitStatus.skip,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      Icons.clear,
                      'CLEAR',
                      Colors.grey,
                      currentStatus == HabitStatus.none,
                      isDateValid, // Pass validation result
                      () {
                        habitNotifier.updateStatus(
                          habit.id,
                          date,
                          HabitStatus.none,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              // Note Section
              ListTile(
                contentPadding: EdgeInsets.zero, // Remove default padding
                leading: Icon(
                  Icons.note_alt_outlined,
                  color: Colors.grey.shade700,
                ),
                title: Text(currentNote.isEmpty ? 'Add Note' : 'Edit Note'),
                // Correctly assign subtitle using ternary operator
                subtitle:
                    currentNote.isEmpty
                        ? null
                        : Text(
                          currentNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet first
                  _showAddNoteDialog(context, habit, date, currentNote);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated Helper for action buttons in bottom sheet
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    bool isSelected,
    bool enabled, // Add enabled flag
    VoidCallback? onPressed, // Make onPressed nullable
  ) {
    // Determine effective onPressed based on enabled status
    final VoidCallback? effectiveOnPressed = enabled ? onPressed : null;
    // Adjust color if disabled
    final Color effectiveColor = enabled ? color : Colors.grey.shade400;

    // Use ElevatedButton for selected, OutlinedButton for others
    return isSelected
        ? ElevatedButton.icon(
          icon: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ), // White icon on colored button
          label: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          onPressed: effectiveOnPressed, // Use effective onPressed
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveColor, // Use effective color
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        )
        : OutlinedButton.icon(
          icon: Icon(
            icon,
            size: 18,
            color: effectiveColor, // Use effective color
          ),
          label: Text(
            label,
            style: TextStyle(fontSize: 11, color: effectiveColor),
          ), // Use effective color
          onPressed: effectiveOnPressed, // Use effective onPressed
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveColor, // Text/Icon color
            side: BorderSide(
              color: effectiveColor.withOpacity(0.5),
            ), // Border color
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
  }

  // --- Add Note Dialog (Copied from HabitCard initially, might need adjustments) ---
  void _showAddNoteDialog(
    BuildContext context,
    Habit habit,
    DateTime date,
    String initialNote,
  ) {
    final controller = TextEditingController(text: initialNote);
    final habitNotifier = ref.read(habitProvider.notifier);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Note for ${DateFormat.yMd().format(date)}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter your note'),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  habitNotifier.updateNote(habit.id, date, controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
  // --- End Add Note Dialog ---

  // Builds the Graphs Tab - Now returns HabitStatsScreen directly
  Widget _buildGraphsTab(Habit habit) {
    // Return the HabitStatsScreen widget, passing the habit
    // and telling it *not* to show its own AppBar
    return HabitStatsScreen(habit: habit, showAppBar: false);
  }

  // Builds the Details Tab
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

  // Helper to normalize date (copied from habit_utils for now)
  // Consider moving to a shared location if used more widely
  DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
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
