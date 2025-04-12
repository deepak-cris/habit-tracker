import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:convert'; // For JSON encoding/decoding the map for Hive
import '../models/achievement.dart';
import '../models/habit.dart';
import '../models/habit_status.dart';
// Removed habit_utils import - calculations are external
// Removed home_screen import

// Provider for the list of *all* predefined achievements
final predefinedAchievementsProvider = Provider<List<Achievement>>((ref) {
  return predefinedAchievements; // Defined in achievement.dart
});

// Provider for the *map* of unlocked achievement IDs to list of habit IDs
// Map<AchievementID, List<HabitID>>
final unlockedAchievementsProvider =
    StateNotifierProvider<AchievementNotifier, Map<String, List<String>>>((
      ref,
    ) {
      return AchievementNotifier(ref);
    });

class AchievementNotifier extends StateNotifier<Map<String, List<String>>> {
  final Ref _ref; // Keep ref for potential future use

  AchievementNotifier(this._ref) : super({}) {
    _loadUnlockedAchievements();
  }

  static const String _boxName = 'userProfile';
  static const String _unlockedKey = 'unlockedAchievementsMap'; // New key name

  Future<void> _loadUnlockedAchievements() async {
    try {
      final box = await Hive.openBox(_boxName);
      // Load the map as a JSON string, then decode
      final String? jsonString = box.get(_unlockedKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
        // Convert dynamic list to List<String>
        state = decodedMap.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
      } else {
        state = {}; // Default to empty map
      }
    } catch (e) {
      print("Error loading unlocked achievements map from Hive: $e");
      state = {};
    }
  }

  Future<void> _saveUnlockedAchievements() async {
    try {
      final box = await Hive.openBox(_boxName);
      // Convert map to JSON string for storage
      final String jsonString = jsonEncode(state);
      await box.put(_unlockedKey, jsonString);
    } catch (e) {
      print("Error saving unlocked achievements map to Hive: $e");
    }
  }

  // Method to unlock a specific achievement for a specific habit
  void unlockAchievement(String achievementId, String habitId) {
    final currentMap = Map<String, List<String>>.from(state);
    final List<String> habitIds = currentMap[achievementId] ?? [];

    if (!habitIds.contains(habitId)) {
      habitIds.add(habitId);
      currentMap[achievementId] = habitIds;
      state = currentMap; // Update state with the modified map
      _saveUnlockedAchievements();
      print("Unlocked achievement '$achievementId' for habit '$habitId'");
      // TODO: Optionally show a notification/snackbar to the user
    }
  }

  // Method to check achievements for a SINGLE habit, given its calculated stats
  // This should be called from HabitNotifier after a habit's state updates
  void checkAndUnlockAchievementsForHabit(
    Habit habit,
    int overallLongestStreak,
  ) {
    // Calculate total completions for this specific habit
    int totalCompletionsThisHabit =
        habit.dateStatus.values.where((s) => s == HabitStatus.done).length;

    for (final achievement in predefinedAchievements) {
      // Check if this specific habit has already unlocked this achievement
      final bool alreadyUnlockedByThisHabit =
          state[achievement.id]?.contains(habit.id) ?? false;
      if (alreadyUnlockedByThisHabit) continue;

      bool criteriaMet = false;
      switch (achievement.criteria['type']) {
        case 'total_completions': // Now checks per habit
          if (totalCompletionsThisHabit >=
              (achievement.criteria['count'] as int)) {
            criteriaMet = true;
          }
          break;
        case 'streak': // Checks per habit streak passed in
          if (overallLongestStreak >= (achievement.criteria['length'] as int)) {
            criteriaMet = true;
          }
          break;
        // 'total_completions_all' needs a separate global check if required
      }

      if (criteriaMet) {
        unlockAchievement(achievement.id, habit.id);
      }
    }
    // Note: Global achievements like 'total_completions_all' might need a separate check function
    // called less frequently or triggered differently.
  }

  // Optional: Reset for testing
  void resetAchievements() {
    state = {};
    _saveUnlockedAchievements();
  }
}
