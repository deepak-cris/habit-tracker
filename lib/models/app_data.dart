import 'package:freezed_annotation/freezed_annotation.dart';
import 'habit.dart';
import 'reward.dart';
import 'claimed_reward.dart';
import 'achievement.dart';
import 'habit_status.dart'; // Assuming this logs habit completions

part 'app_data.freezed.dart';
part 'app_data.g.dart';

@freezed
class AppData with _$AppData {
  const factory AppData({
    required String backupSchemaVersion,
    required DateTime backupTimestamp,
    required List<Habit> habits,
    required List<Reward> rewards,
    required List<ClaimedReward> claimedRewards,
    required List<Achievement> achievements,
    required List<HabitStatus> habitStatuses, // Logs for habit completions
    // Assuming you track user points based on providers/points_provider.dart
    required int userPoints,
    // Add other top-level user data if needed (e.g., settings)
    // Map<String, dynamic>? userSettings,
  }) = _AppData;

  factory AppData.fromJson(Map<String, dynamic> json) =>
      _$AppDataFromJson(json);
}
