import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart'; // Added for JSON serialization
import 'habit_status.dart'; // Import the new enum

part 'habit.g.dart';

// Helper function to convert Map<DateTime, HabitStatus> to Map<String, String> for JSON
Map<String, String> _dateTimeHabitStatusMapToJson(
  Map<DateTime, HabitStatus> map,
) {
  return map.map((key, value) {
    // Convert DateTime key to ISO 8601 string
    final stringKey = key.toIso8601String();
    // Convert HabitStatus enum value to its name string
    final stringValue = value.name;
    return MapEntry(stringKey, stringValue);
  });
}

// Helper function to convert Map<DateTime, String> to Map<String, String> for JSON
Map<String, String> _dateTimeStringMapToJson(Map<DateTime, String> map) {
  return map.map((key, value) {
    // Convert DateTime key to ISO 8601 string
    final stringKey = key.toIso8601String();
    // Value is already a string
    return MapEntry(stringKey, value);
  });
}

// Helper function to convert Map<String, dynamic> back to Map<DateTime, HabitStatus> from JSON
Map<DateTime, HabitStatus> _dateTimeHabitStatusMapFromJson(
  Map<String, dynamic> json,
) {
  return json.map((key, value) {
    // Parse ISO 8601 string key back to DateTime
    final dateTimeKey = DateTime.parse(key);
    // Convert string value back to HabitStatus enum
    // Assumes HabitStatus enum has values matching the stored strings (e.g., 'none', 'completed')
    // Add error handling if value might not match an enum case
    final statusValue = HabitStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitStatus.none, // Default or error case
    );
    return MapEntry(dateTimeKey, statusValue);
  });
}

// Helper function to convert Map<String, dynamic> back to Map<DateTime, String> from JSON
Map<DateTime, String> _dateTimeStringMapFromJson(Map<String, dynamic> json) {
  return json.map((key, value) {
    // Parse ISO 8601 string key back to DateTime
    final dateTimeKey = DateTime.parse(key);
    // Value is already a string
    return MapEntry(dateTimeKey, value as String);
  });
}

@HiveType(typeId: 0) // Keep typeId 0 for Habit
@JsonSerializable() // Added for JSON serialization
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  // Store status per date using a Map
  // Key: Date (normalized to midnight UTC for consistency)
  // Value: HabitStatus enum
  @HiveField(2)
  @JsonKey(
    toJson: _dateTimeHabitStatusMapToJson, // Use specific toJson helper
    fromJson: _dateTimeHabitStatusMapFromJson,
  )
  final Map<DateTime, HabitStatus> dateStatus;

  // Add target streak (optional, default to 21 as per user request)
  @HiveField(3)
  final int targetStreak;

  // Store notes per date
  // Key: Date (normalized to midnight UTC)
  // Value: Note string
  @HiveField(4)
  @JsonKey(
    toJson: _dateTimeStringMapToJson, // Use specific toJson helper
    fromJson: _dateTimeStringMapFromJson,
  )
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

  // Factory constructor for JSON deserialization
  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);

  // Method for JSON serialization
  Map<String, dynamic> toJson() => _$HabitToJson(this);

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
