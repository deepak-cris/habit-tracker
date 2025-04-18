import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../utils/habit_utils.dart'; // Import utils
import '../widgets/detail_cards/habit_strength_card.dart';
import '../widgets/detail_cards/strength_progress_card.dart';
// import '../widgets/detail_cards/punch_card_widget.dart'; // Removed Punch Card import
import '../widgets/detail_cards/best_streaks_card.dart';
import '../widgets/detail_cards/history_calendar_card.dart';
import '../widgets/detail_cards/status_pie_chart_card.dart'; // Import the pie chart card
// Import other necessary models/utils later

// Renamed class
class HabitStatsScreen extends StatefulWidget {
  final Habit habit;
  final bool showAppBar; // Add optional parameter

  const HabitStatsScreen({
    super.key,
    required this.habit,
    this.showAppBar = true, // Default to true
  });

  @override
  State<HabitStatsScreen> createState() => _HabitStatsScreenState();
}

// Enum for Date Range Options - Keep as is or move to utils if used elsewhere
enum DateRangeOption { year, month, week, start, custom }

// Renamed state class
class _HabitStatsScreenState extends State<HabitStatsScreen> {
  DateRangeOption _selectedRange = DateRangeOption.month; // Default range
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange(); // Initialize dates based on default range
  }

  // Updates _fromDate and _toDate based on _selectedRange
  void _updateDateRange({DateTime? customFrom, DateTime? customTo}) {
    final now = DateTime.now();
    _toDate = DateTime.utc(now.year, now.month, now.day); // Today midnight UTC

    switch (_selectedRange) {
      case DateRangeOption.year:
        _fromDate = DateTime.utc(_toDate.year - 1, _toDate.month, _toDate.day);
        break;
      case DateRangeOption.month:
        _fromDate = DateTime.utc(_toDate.year, _toDate.month - 1, _toDate.day);
        break;
      case DateRangeOption.week:
        _fromDate = _toDate.subtract(const Duration(days: 6)); // Inclusive week
        break;
      case DateRangeOption.start:
        // Ensure start date is also normalized UTC midnight
        _fromDate = DateTime.utc(
          widget.habit.startDate.year,
          widget.habit.startDate.month,
          widget.habit.startDate.day,
        );
        break;
      case DateRangeOption.custom:
        // Use provided dates or keep existing if none provided initially
        _fromDate = customFrom ?? _fromDate;
        _toDate = customTo ?? _toDate;
        break;
    }

    // Ensure fromDate is not after toDate (can happen with 'start' if habit started today)
    if (_fromDate.isAfter(_toDate)) {
      _fromDate = _toDate;
    }
  }

  // Function to handle custom date range selection (TODO)
  Future<void> _selectCustomDateRange() async {
    // Implement date pickers using showDatePicker
    // For now, just set to custom and keep existing dates
    setState(() {
      _selectedRange = DateRangeOption.custom;
      // In a real implementation, you'd get dates from pickers here:
      // final pickedFrom = await showDatePicker(...);
      // final pickedTo = await showDatePicker(...);
      // _updateDateRange(customFrom: pickedFrom, customTo: pickedTo);
    });
    print("Custom date range selection needs implementation."); // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    // Build the main content (ListView)
    Widget bodyContent = ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildDateFilter(),
        const SizedBox(height: 20),
        _buildPieChartCard(), // 1. Status Distribution
        const SizedBox(height: 16),
        _buildBestStreaksCard(), // 2. Best Streaks
        const SizedBox(height: 16),
        _buildHabitStrengthCard(), // 3. Habit Strength
        const SizedBox(height: 16),
        _buildHabitStrengthProgressCard(), // 4. Habit Strength Progress
        const SizedBox(height: 16),
        _buildHistoryCard(), // 5. History
        // Punch card already removed
      ],
    );

    // Conditionally wrap with Scaffold and AppBar
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.habit.name),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: bodyContent,
      );
    } else {
      // If AppBar is not shown, just return the body content
      // Add a background color to match the other tabs if needed
      return Container(
        color: Colors.grey[100], // Match background of other tabs
        child: bodyContent,
      );
    }
  }

  // Widget for the Date Range Filter UI
  Widget _buildDateFilter() {
    final dateFormat = DateFormat('dd-MM-yyyy');
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Select the Range:'),
                const Spacer(),
                DropdownButton<DateRangeOption>(
                  value: _selectedRange,
                  items:
                      DateRangeOption.values.map((DateRangeOption range) {
                        String text;
                        switch (range) {
                          case DateRangeOption.year:
                            text = 'Year';
                            break;
                          case DateRangeOption.month:
                            text = 'Month';
                            break;
                          case DateRangeOption.week:
                            text = 'Week';
                            break;
                          case DateRangeOption.start:
                            text = 'Start';
                            break;
                          case DateRangeOption.custom:
                            text = 'Custom';
                            break;
                        }
                        return DropdownMenuItem<DateRangeOption>(
                          value: range,
                          child: Text(text),
                        );
                      }).toList(),
                  onChanged: (DateRangeOption? newValue) {
                    if (newValue != null) {
                      if (newValue == DateRangeOption.custom) {
                        _selectCustomDateRange(); // Handle custom separately
                      } else {
                        setState(() {
                          _selectedRange = newValue;
                          _updateDateRange(); // Update dates based on new selection
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From:', style: TextStyle(color: Colors.grey)),
                    Text(dateFormat.format(_fromDate)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To:', style: TextStyle(color: Colors.grey)),
                    Text(dateFormat.format(_toDate)),
                  ],
                ),
                // Add a button to trigger custom date picker if range is custom
                if (_selectedRange == DateRangeOption.custom)
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: _selectCustomDateRange,
                    tooltip: 'Select Custom Range',
                  )
                else
                  const SizedBox(width: 48), // Maintain spacing
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Card Builder Methods ---

  // Use the actual HabitStrengthCard widget
  Widget _buildHabitStrengthCard() {
    return HabitStrengthCard(
      habit: widget.habit,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // Use the actual StrengthProgressCard widget
  Widget _buildHabitStrengthProgressCard() {
    return StrengthProgressCard(
      habit: widget.habit,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // Removed _buildPunchCard method

  // Use the actual BestStreaksCard widget
  Widget _buildBestStreaksCard() {
    return BestStreaksCard(
      habit: widget.habit,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // Use the actual HistoryCalendarCard widget
  Widget _buildHistoryCard() {
    return HistoryCalendarCard(
      habit: widget.habit,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // Use the actual StatusPieChartCard widget
  Widget _buildPieChartCard() {
    return StatusPieChartCard(
      habit: widget.habit,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }
} // End of _HabitStatsScreenState // Renamed state class

// Helper extension for date formatting (optional)
extension DateOnlyCompare on DateTime {
  String toShortDateString() => DateFormat('yyyy-MM-dd').format(this);
}
