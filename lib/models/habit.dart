import 'package:hive/hive.dart';
import 'habit_status.dart'; // Import the new enum

part 'habit.g.dart';

@HiveType(typeId: 0) // Keep typeId 0 for Habit
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  // Store status per date using a Map
  // Key: Date (normalized to midnight UTC for consistency)
  // Value: HabitStatus enum
  @HiveField(2)
  final Map<DateTime, HabitStatus> dateStatus;

  // Add target streak (optional, default to 21 as per user request)
  @HiveField(3)
  final int targetStreak;

  // Store notes per date
  // Key: Date (normalized to midnight UTC)
  // Value: Note string
  @HiveField(4)
  final Map<DateTime, String> notes;

  @HiveField(5)
  final String? description; // Optional description

  @HiveField(6)
  final List<String> reasons; // List of reasons

  @HiveField(7)
  final DateTime startDate; // Habit start date

  @HiveField(8)
  final String scheduleType; // e.g., "Fixed", "Flexible"

  @HiveField(9)
  final List<bool> selectedDays; // For fixed schedule (length 7, Su-Sa)

  @HiveField(10)
  final bool isMastered; // Flag for 21-day streak completion

  @HiveField(11) // Next available index
  // Store as {'hour': H, 'minute': M, 'note': String?}
  final List<Map<String, dynamic>>? reminderTimes;

  @HiveField(12) // New field for schedule type
  final String reminderScheduleType; // 'none', 'daily', 'weekly', 'specific_date'

  @HiveField(13) // New field for specific date/time
  final DateTime? reminderSpecificDateTime; // Used only if type is 'specific_date'

  // TODO: Add fields for flexible schedule if needed (e.g., frequency, interval)

  Habit({
    required this.id,
    required this.name,
    required this.dateStatus,
    required this.notes,
    this.description, // Make optional
    this.reasons = const [], // Default to empty list
    required this.startDate,
    this.scheduleType = 'Fixed', // Default schedule
    required this.selectedDays,
    this.targetStreak = 21,
    this.isMastered = false, // Default to false
    this.reminderTimes, // Add reminderTimes to constructor
    this.reminderScheduleType = 'weekly', // Default to weekly
    this.reminderSpecificDateTime, // Default to null
  });

  // Helper to get status for a specific date (defaults to none)
  HabitStatus getStatusForDate(DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return dateStatus[normalizedDate] ?? HabitStatus.none;
  }

  // Helper to get note for a specific date (defaults to empty string)
  String getNoteForDate(DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return notes[normalizedDate] ?? '';
  }
}
