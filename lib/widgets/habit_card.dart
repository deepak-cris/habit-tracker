import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
import '../screens/home_screen.dart'; // For habitProvider
import '../utils/habit_utils.dart'; // Import habit utils for normalizeDate
import '../screens/habit_detail_screen.dart'; // Import the detail screen
import '../screens/add_edit_habit_screen.dart'; // Import for Edit navigation
import '../screens/habit_reminders_screen.dart'; // Import for Reminders navigation
import '../screens/habit_stats_screen.dart'; // Import for Stats navigation

// Convert to ConsumerStatefulWidget for local state (expansion) and provider access
class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  bool _isExpanded = false;
  DateTime _selectedDate = DateTime.utc(
    // Initialize selected date to today (normalized)
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // Controller for the PageView
  static const int _initialPage = 1000;
  final PageController _pageController = PageController(
    initialPage: _initialPage,
  );
  int _currentPage = _initialPage; // Track current page for arrow updates

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final currentNote = habit.getNoteForDate(_selectedDate);

    List<Widget> columnChildren = [
      // Top Row: Habit Name and Menu
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wrap name in a Row to add the mastered icon
          Row(
            children: [
              Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show star if mastered
              if (habit.isMastered) // Check the isMastered flag
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.star, // Display star icon
                    color: Colors.amber.shade700, // Gold color
                    size: 18,
                  ),
                ),
            ],
          ),
          // IconButton( // REMOVE Original placeholder IconButton
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () {
          //     /* TODO: Options menu */
          //   },
          // ),
          // Keep ONLY the new PopupMenuButton for options
          _buildOptionsMenu(context, ref, habit),
        ],
      ),
      const SizedBox(height: 10),
      // Middle Row: Weekly Calendar View
      _buildWeeklyCalendar(habit),
      const SizedBox(height: 10),
    ];

    if (_isExpanded) {
      columnChildren.addAll([
        _buildActionButtons(),
        const SizedBox(height: 10),
        // Tappable note display
        GestureDetector(
          onTap:
              () => _showAddNoteDialog(
                context,
                habit,
                _selectedDate,
                currentNote,
              ),
          child: Container(
            width: double.infinity, // Take full width
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              currentNote.isEmpty ? 'Tap to add note' : currentNote,
              style: TextStyle(
                color:
                    currentNote.isEmpty ? Colors.grey.shade600 : Colors.black87,
                fontStyle:
                    currentNote.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ]);
    }

    // Add the combined bottom row (streak info + action icons)
    columnChildren.add(_buildCombinedBottomRow(context, habit));

    // Wrap the main content Column in GestureDetector for navigation
    // Exclude the calendar area from this tap target later if needed,
    // but for now, tapping anywhere navigates.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        // Use InkWell for ripple effect
        onTap: () {
          // Navigate to HabitDetailScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(habit: habit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columnChildren,
          ),
        ),
      ),
    );
  }

  // --- Options Menu ---
  Widget _buildOptionsMenu(BuildContext context, WidgetRef ref, Habit habit) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (String result) {
        switch (result) {
          case 'edit':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => AddEditHabitScreen(
                      habit: habit,
                    ), // Opens Edit tab by default
              ),
            );
            break;
          case 'details': // Add case for details navigation
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HabitDetailScreen(habit: habit),
              ),
            );
            break;
          case 'stats':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HabitStatsScreen(habit: habit),
              ),
            );
            break;
          case 'reminders':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => HabitRemindersScreen(
                      habit: habit,
                    ), // Navigate to new screen
              ),
            );
            break;
          case 'delete':
            _showDeleteConfirmation(context, ref, habit);
            break;
        }
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              // Add View Details item first
              value: 'details',
              child: ListTile(
                leading: Icon(Icons.visibility_outlined),
                title: Text('View Details'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Habit'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'stats',
              child: ListTile(
                leading: Icon(Icons.bar_chart_outlined),
                title: Text('View Statistics'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'reminders',
              child: ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Reminders'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
    );
  }

  // --- Delete Confirmation Dialog ---
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Habit?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${habit.name}"?'),
                const Text('This action cannot be undone.'),
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
                ref.read(habitProvider.notifier).deleteHabit(habit.id);
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Optionally show a snackbar confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Habit "${habit.name}" deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
  // --- End Delete Confirmation ---

  // Builds the horizontally scrollable weekly calendar
  Widget _buildWeeklyCalendar(Habit habit) {
    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, pageIndex) {
          final weekOffset = pageIndex - _initialPage;
          final now = DateTime.now();
          final startOfThisWeek = now.subtract(Duration(days: now.weekday % 7));
          final startOfWeekForPage = startOfThisWeek.add(
            Duration(days: weekOffset * 7),
          );
          return _buildWeekView(habit, startOfWeekForPage);
        },
      ),
    );
  }

  // Builds the view for a single week within the PageView
  Widget _buildWeekView(Habit habit, DateTime startOfWeek) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
    final dayFormatter = DateFormat('E');
    final dateFormatter = DateFormat('d');

    // Build the list of widgets for the Row, including dividers
    List<Widget> rowChildren = [];
    for (int index = 0; index < days.length; index++) {
      final day = days[index];
      final normalizedDay = DateTime.utc(day.year, day.month, day.day);
      final isToday = DateUtils.isSameDay(
        normalizedDay,
        DateTime.utc(now.year, now.month, now.day),
      );
      final isSelected = DateUtils.isSameDay(normalizedDay, _selectedDate);
      final currentStatus = habit.getStatusForDate(normalizedDay);

      // Check previous day status for connector line
      HabitStatus previousStatus = HabitStatus.none;
      if (index > 0) {
        final prevDay = days[index - 1];
        final normalizedPrevDay = DateTime.utc(
          prevDay.year,
          prevDay.month,
          prevDay.day,
        );
        previousStatus = habit.getStatusForDate(normalizedPrevDay);
      }
      bool showConnector =
          index > 0 &&
          currentStatus == HabitStatus.done &&
          previousStatus == HabitStatus.done;

      // Add connector line or spacer if needed (before the circle)
      if (index > 0) {
        // Add spacer/connector for all but the first item
        rowChildren.add(
          Expanded(
            child: Center(
              child: Container(
                height: showConnector ? 5 : 0, // Show line only if needed
                color:
                    showConnector ? Colors.green.shade300 : Colors.transparent,
              ),
            ),
          ),
        );
      }

      // Add the date circle
      rowChildren.add(
        GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedDate == normalizedDay) {
                _isExpanded = !_isExpanded;
              } else {
                _selectedDate = normalizedDay;
                _isExpanded = true;
              }
            });
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getDayColor(currentStatus, isToday),
              shape: BoxShape.circle,
              border:
                  isSelected
                      ? Border.all(color: Colors.blueAccent, width: 2.0)
                      : null,
            ),
            child: Center(
              child: Text(
                dateFormatter.format(day),
                style: TextStyle(
                  color: _getTextColor(currentStatus, isToday),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Ensure the row has the correct number of children (7 circles + 6 spacers/connectors)
    // If the loop didn't add enough spacers (e.g., if length is 0), this might need adjustment,
    // but for a fixed length of 7, it should be correct.

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Day Abbreviations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              days.map((day) {
                String shortDay = dayFormatter.format(day).substring(0, 2);
                return SizedBox(
                  width: 30, // Match circle width for alignment
                  child: Text(
                    shortDay,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 4),
        // Date Circles Row (with connectors/spacers)
        Row(
          // Let Expanded handle spacing
          children: rowChildren,
        ),
      ],
    );
  }

  // Helper to get background color based on status and isToday
  Color _getDayColor(HabitStatus status, bool isToday) {
    switch (status) {
      case HabitStatus.done:
        return Colors.green.shade300;
      case HabitStatus.fail:
        return Colors.red.shade300;
      case HabitStatus.skip:
        return Colors.orange.shade300;
      case HabitStatus.none:
      default:
        return isToday ? Colors.teal.shade300 : Colors.grey.shade200;
    }
  }

  // Helper to get text color based on status and isToday
  Color _getTextColor(HabitStatus status, bool isToday) {
    switch (status) {
      case HabitStatus.done:
      case HabitStatus.fail:
      case HabitStatus.skip:
        return Colors.white;
      case HabitStatus.none:
      default:
        return isToday ? Colors.white : Colors.black87;
    }
  }

  // Helper method to build the action buttons row
  Widget _buildActionButtons() {
    final dateForAction = _selectedDate; // Already normalized in onTap
    final habitNotifier = ref.read(habitProvider.notifier);
    // Get normalized dates for comparison
    final habitStartDate = normalizeDate(widget.habit.startDate);
    final today = normalizeDate(DateTime.now());

    // Determine if the selected date is valid for actions
    final bool isDateValid =
        !dateForAction.isAfter(today) &&
        !dateForAction.isBefore(habitStartDate);

    // Build the action buttons row first
    final actionButtonRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          Icons.check_circle,
          'DONE',
          Colors.green,
          isDateValid,
          () {
            habitNotifier.updateStatus(
              widget.habit.id,
              dateForAction,
              HabitStatus.done,
            );
            setState(() => _isExpanded = false);
          },
        ),
        _buildVerticalDivider(),
        _buildActionButton(Icons.cancel, 'FAIL', Colors.red, isDateValid, () {
          habitNotifier.updateStatus(
            widget.habit.id,
            dateForAction,
            HabitStatus.fail,
          );
          setState(() => _isExpanded = false);
        }),
        _buildVerticalDivider(),
        _buildActionButton(
          Icons.skip_next,
          'SKIP',
          Colors.orange,
          isDateValid,
          () {
            habitNotifier.updateStatus(
              widget.habit.id,
              dateForAction,
              HabitStatus.skip,
            );
            setState(() => _isExpanded = false);
          },
        ),
        _buildVerticalDivider(),
        _buildActionButton(Icons.clear, 'CLEAR', Colors.grey, isDateValid, () {
          habitNotifier.updateStatus(
            widget.habit.id,
            dateForAction,
            HabitStatus.none,
          );
          setState(() => _isExpanded = false);
        }),
      ],
    );

    // Conditionally add the info note above the buttons if the date is invalid
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ), // Add horizontal padding
      decoration: BoxDecoration(
        color:
            isDateValid
                ? Colors.teal.shade100
                : Colors.grey.shade300, // Change background if invalid
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        // Use Column to stack note and buttons
        children: [
          if (!isDateValid) // Show note only if date is invalid
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Marking allowed from start date to today only.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          actionButtonRow, // Add the row of buttons
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    bool enabled, // Add enabled flag
    VoidCallback? onPressed, // Make onPressed nullable
  ) {
    // Use the enabled flag to determine the effective onPressed callback
    final VoidCallback? effectiveOnPressed = enabled ? onPressed : null;
    // Adjust color if disabled
    final Color effectiveColor = enabled ? color : Colors.grey.shade400;

    return TextButton.icon(
      icon: Icon(icon, color: effectiveColor, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: effectiveColor, // Use effective color
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: effectiveOnPressed, // Use effective onPressed
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.teal.shade200);
  }

  // --- Streak Calculation Logic ---
  int _calculateCurrentStreak(Map<DateTime, HabitStatus> dateStatus) {
    int streak = 0;
    DateTime checkDate = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    while (true) {
      final status = dateStatus[checkDate];
      if (status == HabitStatus.done) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (status == HabitStatus.skip) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(Map<DateTime, HabitStatus> dateStatus) {
    if (dateStatus.isEmpty) return 0;
    int longestStreak = 0;
    int currentStreak = 0;
    final sortedDates = dateStatus.keys.toList()..sort();
    DateTime? previousDate;
    for (final date in sortedDates) {
      final status = dateStatus[date];
      if (status == HabitStatus.done) {
        if (previousDate != null && date.difference(previousDate).inDays == 1) {
          currentStreak++;
        } else if (previousDate != null &&
            date.difference(previousDate).inDays > 1) {
          bool gapIsOnlySkips = true;
          for (int i = 1; i < date.difference(previousDate).inDays; i++) {
            DateTime gapDate = previousDate.add(Duration(days: i));
            if (dateStatus[gapDate] != HabitStatus.skip) {
              gapIsOnlySkips = false;
              break;
            }
          }
          currentStreak = gapIsOnlySkips ? currentStreak + 1 : 1;
        } else {
          currentStreak = 1;
        }
      } else if (status != HabitStatus.skip) {
        currentStreak = 0;
      }
      if (currentStreak > longestStreak) longestStreak = currentStreak;
      if (status != HabitStatus.skip) previousDate = date;
    }
    return longestStreak;
  }
  // --- End Streak Calculation ---

  // --- Helper method to build the combined bottom row (Streak + Actions) ---
  Widget _buildCombinedBottomRow(BuildContext context, Habit habit) {
    final currentStreak = _calculateCurrentStreak(habit.dateStatus);
    final longestStreak = _calculateLongestStreak(habit.dateStatus);
    final targetCompletions = habit.targetStreak;

    // Define icon color and size for consistency
    final Color actionIconColor =
        Theme.of(context).colorScheme.primary; // Use primary color
    const double actionIconSize = 22.0; // Slightly smaller icons
    const EdgeInsets iconPadding = EdgeInsets.symmetric(
      horizontal: 6.0,
    ); // Padding around icons

    return Padding(
      padding: const EdgeInsets.only(top: 12.0), // Add padding above the row
      child: Row(
        children: [
          // Streak Info (Left Aligned)
          const Icon(
            Icons.local_fire_department_outlined,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 12), // Reduced spacing
          const Icon(Icons.star_border, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '$longestStreak / $targetCompletions',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          // Spacer to push icons to the right
          const Spacer(),

          // Action Icons (Right Aligned - Reordered)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: actionIconColor,
              size: actionIconSize,
            ),
            tooltip: 'Edit Habit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditHabitScreen(habit: habit),
                ),
              );
            },
            padding: iconPadding,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          IconButton(
            icon: Icon(
              Icons.bar_chart_outlined,
              color: actionIconColor,
              size: actionIconSize,
            ),
            tooltip: 'View Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitStatsScreen(habit: habit),
                ),
              );
            },
            padding: iconPadding,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_active_outlined,
              color: actionIconColor,
              size: actionIconSize,
            ),
            tooltip: 'Reminders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitRemindersScreen(habit: habit),
                ),
              );
            },
            padding: iconPadding,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          // Arrow Icon (Moved to the end)
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios, // Changed icon
              color: actionIconColor,
              size: actionIconSize - 2, // Slightly smaller arrow
            ),
            // Removed tooltip
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HabitDetailScreen(habit: habit),
                ),
              );
            },
            padding: iconPadding,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
  // --- End Combined Bottom Row ---

  // --- Add Note Dialog ---
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
}
