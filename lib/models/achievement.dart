// Note: Achievements are predefined, so they don't need Hive persistence directly.
// We only need to store the IDs of the *unlocked* achievements.

import 'package:json_annotation/json_annotation.dart'; // Added

part 'achievement.g.dart'; // Added for JSON generation

@JsonSerializable(
  explicitToJson: true,
) // Added, explicitToJson for the criteria map
class Achievement {
  final String id; // e.g., "7_day_streak", "30_completions"
  final String name;
  final String description;
  final int iconCodePoint; // Use codePoint for easy Icon creation
  // Criteria could be more complex, using a class/enum later if needed
  final Map<String, dynamic> criteria;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.criteria,
  });

  // Factory constructor for JSON deserialization
  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  // Method for JSON serialization
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

// --- Predefined Achievements List ---

const List<Achievement> predefinedAchievements = [
  Achievement(
    id: 'first_completion',
    name: 'First Step!',
    // Add placeholder for habit name
    description: 'Completed {habitName} for the first time.',
    iconCodePoint: 0xe150, // Example: Icons.check_circle_outline.codePoint
    criteria: {'type': 'total_completions', 'count': 1},
  ),
  Achievement(
    id: '7_day_streak',
    name: 'Week Warrior',
    // Add placeholder for habit name
    description: 'Maintained a 7-day streak for {habitName}.',
    iconCodePoint: 0xf147, // Example: Icons.local_fire_department.codePoint
    criteria: {'type': 'streak', 'length': 7},
  ),
  Achievement(
    id: '21_day_streak', // Moved 21 day here for order
    name: 'Habit Builder',
    // Add placeholder for habit name
    description: 'Maintained a 21-day streak for {habitName}.',
    iconCodePoint:
        0xf147, // Example: Icons.local_fire_department.codePoint (Maybe different color?)
    criteria: {'type': 'streak', 'length': 21},
  ),
  Achievement(
    id: '30_day_streak',
    name: 'Month Master',
    // Add placeholder for habit name
    description: 'Maintained a 30-day streak for {habitName}.',
    iconCodePoint:
        0xf147, // Example: Icons.local_fire_department.codePoint (Maybe different color?)
    criteria: {'type': 'streak', 'length': 30},
  ),
  // Note: 'total_completions_all' doesn't fit the per-habit model well,
  // so it might need separate handling or removal if we strictly show per-habit unlocks.
  // Keeping it for now, but its display might be odd in the new list format.
  Achievement(
    id: '100_completions_all', // Renamed ID slightly for clarity
    name: 'Century Club',
    description: 'Completed habits 100 times in total across all habits.',
    iconCodePoint: 0xf063d, // Example: Icons.military_tech.codePoint
    criteria: {
      'type': 'total_completions_all',
      'count': 100,
    }, // This criteria type needs special handling
  ),
  // Add more achievement ideas here...
];
