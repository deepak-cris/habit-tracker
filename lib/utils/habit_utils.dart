import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting if needed later
import '../models/habit.dart';
import '../models/habit_status.dart';

/// Calculates the data points for a habit's progress graph.
///
/// The X value represents the day index (0 for today, 1 for yesterday, etc., up to daysToShow - 1).
/// The Y value represents the percentage completion based on the max streak achieved up to that day.
/// percentage(d) = (max streak up to date d / target streak) * 100 (capped at 100).
List<FlSpot> calculateHabitGraphData(Habit habit, {int daysToShow = 30}) {
  final List<FlSpot> spots = [];
  final today = DateTime.now();
  final normalizedToday = DateTime.utc(today.year, today.month, today.day);

  // Ensure targetStreak is positive to avoid division by zero or negative streaks
  final targetStreak = max(1, habit.targetStreak);

  for (int i = 0; i < daysToShow; i++) {
    // Calculate the date for this point (going back i days from today)
    final dateForPoint = normalizedToday.subtract(Duration(days: i));

    // Ensure we don't calculate for dates before the habit started
    if (dateForPoint.isBefore(habit.startDate)) {
      // Optionally add a zero point or skip, let's add zero for now
      // We plot from right to left (index 0 is today), so use daysToShow - 1 - i for X
      spots.add(FlSpot((daysToShow - 1 - i).toDouble(), 0.0));
      continue;
    }

    // Calculate the maximum streak achieved up to 'dateForPoint'
    int maxStreak = _calculateMaxStreakUpToDate(habit, dateForPoint);

    // Calculate the percentage, capping at 100%
    double percentage = min(100.0, (maxStreak / targetStreak) * 100.0);
    if (percentage.isNaN || percentage.isInfinite) {
      percentage =
          0.0; // Handle potential division by zero if targetStreak was 0 initially
    }

    // Add the spot. X-axis is reversed index (0 = today, 1 = yesterday...)
    // We want the graph to read left-to-right chronologically.
    // So, the furthest day back (i = daysToShow - 1) should be X = 0.
    // Today (i = 0) should be X = daysToShow - 1.
    spots.add(FlSpot((daysToShow - 1 - i).toDouble(), percentage));
  }

  // Ensure spots are sorted by X value if needed (should be inherently sorted by loop)
  // spots.sort((a, b) => a.x.compareTo(b.x));

  // If no spots were generated (e.g., daysToShow is 0 or habit started recently), return empty list or a default point
  if (spots.isEmpty) {
    return [FlSpot(0, 0)]; // Default point if needed
  }

  return spots;
}

/// Data structure for Punch Card results.
class PunchCardData {
  // Map<Month (1-12), Map<DayOfWeek (1-7, Mon-Sun), Count>>
  final Map<int, Map<int, int>> monthlyWeekdayCounts;
  final int maxCount; // Maximum count in any single slot

  PunchCardData({required this.monthlyWeekdayCounts, required this.maxCount});
}

/// Calculates the data needed for the punch card visualization within a date range.
PunchCardData calculatePunchCardData(
  Habit habit,
  DateTime fromDate,
  DateTime toDate,
) {
  final normalizedFrom = normalizeDate(fromDate);
  final normalizedTo = normalizeDate(toDate);
  final Map<int, Map<int, int>> counts = {}; // Month -> DayOfWeek -> Count
  int maxCount = 0;

  if (normalizedFrom.isAfter(normalizedTo)) {
    return PunchCardData(
      monthlyWeekdayCounts: counts,
      maxCount: maxCount,
    ); // Invalid range
  }

  DateTime currentDate = normalizedFrom;
  while (!currentDate.isAfter(normalizedTo)) {
    // Only consider days on or after the habit's start date
    if (!currentDate.isBefore(normalizeDate(habit.startDate))) {
      final status = habit.dateStatus[currentDate] ?? HabitStatus.none;
      if (status == HabitStatus.done) {
        final month = currentDate.month;
        final weekday = currentDate.weekday; // 1 (Monday) to 7 (Sunday)

        // Initialize maps if they don't exist
        counts.putIfAbsent(month, () => {});
        counts[month]!.putIfAbsent(weekday, () => 0);

        // Increment count
        counts[month]![weekday] = counts[month]![weekday]! + 1;

        // Update max count
        if (counts[month]![weekday]! > maxCount) {
          maxCount = counts[month]![weekday]!;
        }
      }
    }
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return PunchCardData(monthlyWeekdayCounts: counts, maxCount: maxCount);
}

/// Data structure for Best Streak result.
class StreakInfo {
  final int length;
  final DateTime? startDate; // Start date of the best streak found
  final DateTime? endDate; // End date of the best streak found

  StreakInfo({required this.length, this.startDate, this.endDate});
}

/// Calculates the longest consecutive 'done' streak within a given date range.
StreakInfo calculateBestStreakInRange(
  Habit habit,
  DateTime fromDate,
  DateTime toDate,
) {
  final normalizedFrom = normalizeDate(fromDate);
  final normalizedTo = normalizeDate(toDate);

  int longestStreak = 0;
  int currentStreak = 0;
  DateTime? bestStreakStartDate;
  DateTime? bestStreakEndDate;
  DateTime? currentStreakStartDate;

  if (normalizedFrom.isAfter(normalizedTo)) {
    return StreakInfo(length: 0); // Invalid range
  }

  DateTime currentDate = normalizedFrom;
  while (!currentDate.isAfter(normalizedTo)) {
    // Only consider days on or after the habit's start date
    if (!currentDate.isBefore(normalizeDate(habit.startDate))) {
      final status = habit.dateStatus[currentDate] ?? HabitStatus.none;

      if (status == HabitStatus.done) {
        if (currentStreak == 0) {
          currentStreakStartDate =
              currentDate; // Start of a new potential streak
        }
        currentStreak++;
      } else {
        // End of the current streak (if any)
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
          bestStreakStartDate = currentStreakStartDate;
          // End date is the day *before* the streak broke
          bestStreakEndDate = currentDate.subtract(const Duration(days: 1));
        }
        currentStreak = 0;
        currentStreakStartDate = null;
      }
    } else {
      // If before start date, reset any potential streak starting from outside the valid range
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
        bestStreakStartDate = currentStreakStartDate;
        bestStreakEndDate = currentDate.subtract(const Duration(days: 1));
      }
      currentStreak = 0;
      currentStreakStartDate = null;
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  // Final check in case the longest streak continued right up to toDate
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
    bestStreakStartDate = currentStreakStartDate;
    bestStreakEndDate = normalizedTo; // Streak ended on the last day
  }

  return StreakInfo(
    length: longestStreak,
    startDate: bestStreakStartDate,
    endDate: bestStreakEndDate,
  );
}

/// Calculates the distribution of statuses (Done, Fail, Skip, None) within a date range.
Map<HabitStatus, int> calculateStatusDistribution(
  Habit habit,
  DateTime fromDate,
  DateTime toDate,
) {
  final normalizedFrom = normalizeDate(fromDate);
  final normalizedTo = normalizeDate(toDate);
  final Map<HabitStatus, int> distribution = {
    HabitStatus.done: 0,
    HabitStatus.fail: 0,
    HabitStatus.skip: 0,
    HabitStatus.none:
        0, // Count 'none' as well for completeness, maybe filter later
  };

  if (normalizedFrom.isAfter(normalizedTo)) {
    return distribution; // Invalid range
  }

  DateTime currentDate = normalizedFrom;
  while (!currentDate.isAfter(normalizedTo)) {
    // Only consider days on or after the habit's start date
    if (!currentDate.isBefore(normalizeDate(habit.startDate))) {
      final status = habit.dateStatus[currentDate] ?? HabitStatus.none;
      distribution[status] = (distribution[status] ?? 0) + 1;
    } else {
      // If before start date but within range, count it as 'none' for the range duration?
      // Or ignore? Let's ignore for now, only count days >= startDate.
    }
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return distribution;
}

/// Calculates the maximum consecutive streak of 'completed' days ending on or before [endDate].
int _calculateMaxStreakUpToDate(Habit habit, DateTime endDate) {
  int maxStreak = 0;
  int currentStreak = 0;

  // Normalize endDate
  final normalizedEndDate = DateTime.utc(
    endDate.year,
    endDate.month,
    endDate.day,
  );

  // Iterate from the habit's start date up to the endDate
  DateTime currentDate = habit.startDate;
  while (!currentDate.isAfter(normalizedEndDate)) {
    final normalizedCurrentDate = DateTime.utc(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final status = habit.dateStatus[normalizedCurrentDate] ?? HabitStatus.none;

    if (status == HabitStatus.done) {
      // Corrected from .completed to .done
      currentStreak++;
    } else {
      // Reset streak if not completed (missed, skipped, or none)
      maxStreak = max(maxStreak, currentStreak);
      currentStreak = 0;
    }

    // Move to the next day
    currentDate = currentDate.add(const Duration(days: 1));
  }

  // Final check in case the streak continued up to the endDate
  maxStreak = max(maxStreak, currentStreak);

  return maxStreak;
}

/// Helper to normalize a DateTime to midnight UTC.
DateTime normalizeDate(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day);
}

/// Calculates the habit strength percentage within a given date range.
/// Strength = (Days Done / Total Days in Range) * 100
double calculateHabitStrength(Habit habit, DateTime fromDate, DateTime toDate) {
  // Ensure dates are normalized
  final normalizedFrom = normalizeDate(fromDate);
  final normalizedTo = normalizeDate(toDate);

  if (normalizedFrom.isAfter(normalizedTo)) {
    return 0.0; // Invalid range
  }

  int doneCount = 0;
  int totalDays = 0;

  DateTime currentDate = normalizedFrom;
  while (!currentDate.isAfter(normalizedTo)) {
    // Only count days that are on or after the habit's start date
    if (!currentDate.isBefore(normalizeDate(habit.startDate))) {
      totalDays++;
      final status = habit.dateStatus[currentDate] ?? HabitStatus.none;
      if (status == HabitStatus.done) {
        doneCount++;
      }
    }
    currentDate = currentDate.add(const Duration(days: 1));
  }

  if (totalDays == 0) {
    return 0.0; // Avoid division by zero if range has no valid days
  }

  double strength = (doneCount / totalDays) * 100.0;
  return strength.isNaN ? 0.0 : strength; // Handle potential NaN
}

/// Calculates data points for the strength progress line chart within a range.
/// Y-value for day 'd' = (Done Days from fromDate to d) / (Total Days from fromDate to d) * 100
List<FlSpot> calculateStrengthProgressData(
  Habit habit,
  DateTime fromDate,
  DateTime toDate,
) {
  // Ensure dates are normalized
  final normalizedFrom = normalizeDate(fromDate);
  final normalizedTo = normalizeDate(toDate);
  final List<FlSpot> spots = [];

  if (normalizedFrom.isAfter(normalizedTo)) {
    return spots; // Invalid range
  }

  int cumulativeDoneCount = 0;
  int cumulativeTotalDays = 0;
  double dayIndex = 0; // X-axis value

  DateTime currentDate = normalizedFrom;
  while (!currentDate.isAfter(normalizedTo)) {
    // Only consider days on or after the habit's start date
    if (!currentDate.isBefore(normalizeDate(habit.startDate))) {
      cumulativeTotalDays++;
      final status = habit.dateStatus[currentDate] ?? HabitStatus.none;
      if (status == HabitStatus.done) {
        cumulativeDoneCount++;
      }

      double cumulativeStrength = 0.0;
      if (cumulativeTotalDays > 0) {
        cumulativeStrength =
            (cumulativeDoneCount / cumulativeTotalDays) * 100.0;
      }
      cumulativeStrength =
          cumulativeStrength.isNaN ? 0.0 : cumulativeStrength; // Handle NaN

      spots.add(FlSpot(dayIndex, cumulativeStrength));
    } else {
      // If before start date but within range, add a zero point to maintain axis length
      spots.add(FlSpot(dayIndex, 0.0));
    }

    currentDate = currentDate.add(const Duration(days: 1));
    dayIndex++;
  }

  // If the loop didn't run (e.g., fromDate == toDate and it's before startDate), add a default point
  if (spots.isEmpty && dayIndex == 0) {
    spots.add(FlSpot(0, 0));
  }

  return spots;
}
