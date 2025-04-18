// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppDataImpl _$$AppDataImplFromJson(Map<String, dynamic> json) =>
    _$AppDataImpl(
      backupSchemaVersion: json['backupSchemaVersion'] as String,
      backupTimestamp: DateTime.parse(json['backupTimestamp'] as String),
      habits: (json['habits'] as List<dynamic>)
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewards: (json['rewards'] as List<dynamic>)
          .map((e) => Reward.fromJson(e as Map<String, dynamic>))
          .toList(),
      claimedRewards: (json['claimedRewards'] as List<dynamic>)
          .map((e) => ClaimedReward.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      habitStatuses: (json['habitStatuses'] as List<dynamic>)
          .map((e) => $enumDecode(_$HabitStatusEnumMap, e))
          .toList(),
      userPoints: (json['userPoints'] as num).toInt(),
    );

Map<String, dynamic> _$$AppDataImplToJson(_$AppDataImpl instance) =>
    <String, dynamic>{
      'backupSchemaVersion': instance.backupSchemaVersion,
      'backupTimestamp': instance.backupTimestamp.toIso8601String(),
      'habits': instance.habits.map((e) => e.toJson()).toList(),
      'rewards': instance.rewards.map((e) => e.toJson()).toList(),
      'claimedRewards': instance.claimedRewards.map((e) => e.toJson()).toList(),
      'achievements': instance.achievements.map((e) => e.toJson()).toList(),
      'habitStatuses':
          instance.habitStatuses.map((e) => _$HabitStatusEnumMap[e]!).toList(),
      'userPoints': instance.userPoints,
    };

const _$HabitStatusEnumMap = {
  HabitStatus.none: 'none',
  HabitStatus.done: 'done',
  HabitStatus.fail: 'fail',
  HabitStatus.skip: 'skip',
};
