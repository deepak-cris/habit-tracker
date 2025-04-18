// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppData _$AppDataFromJson(Map<String, dynamic> json) {
  return _AppData.fromJson(json);
}

/// @nodoc
mixin _$AppData {
  String get backupSchemaVersion => throw _privateConstructorUsedError;
  DateTime get backupTimestamp => throw _privateConstructorUsedError;
  List<Habit> get habits => throw _privateConstructorUsedError;
  List<Reward> get rewards => throw _privateConstructorUsedError;
  List<ClaimedReward> get claimedRewards => throw _privateConstructorUsedError;
  List<Achievement> get achievements => throw _privateConstructorUsedError;
  List<HabitStatus> get habitStatuses =>
      throw _privateConstructorUsedError; // Logs for habit completions
// Assuming you track user points based on providers/points_provider.dart
  int get userPoints => throw _privateConstructorUsedError;

  /// Serializes this AppData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppDataCopyWith<AppData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppDataCopyWith<$Res> {
  factory $AppDataCopyWith(AppData value, $Res Function(AppData) then) =
      _$AppDataCopyWithImpl<$Res, AppData>;
  @useResult
  $Res call(
      {String backupSchemaVersion,
      DateTime backupTimestamp,
      List<Habit> habits,
      List<Reward> rewards,
      List<ClaimedReward> claimedRewards,
      List<Achievement> achievements,
      List<HabitStatus> habitStatuses,
      int userPoints});
}

/// @nodoc
class _$AppDataCopyWithImpl<$Res, $Val extends AppData>
    implements $AppDataCopyWith<$Res> {
  _$AppDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backupSchemaVersion = null,
    Object? backupTimestamp = null,
    Object? habits = null,
    Object? rewards = null,
    Object? claimedRewards = null,
    Object? achievements = null,
    Object? habitStatuses = null,
    Object? userPoints = null,
  }) {
    return _then(_value.copyWith(
      backupSchemaVersion: null == backupSchemaVersion
          ? _value.backupSchemaVersion
          : backupSchemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      backupTimestamp: null == backupTimestamp
          ? _value.backupTimestamp
          : backupTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      habits: null == habits
          ? _value.habits
          : habits // ignore: cast_nullable_to_non_nullable
              as List<Habit>,
      rewards: null == rewards
          ? _value.rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<Reward>,
      claimedRewards: null == claimedRewards
          ? _value.claimedRewards
          : claimedRewards // ignore: cast_nullable_to_non_nullable
              as List<ClaimedReward>,
      achievements: null == achievements
          ? _value.achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as List<Achievement>,
      habitStatuses: null == habitStatuses
          ? _value.habitStatuses
          : habitStatuses // ignore: cast_nullable_to_non_nullable
              as List<HabitStatus>,
      userPoints: null == userPoints
          ? _value.userPoints
          : userPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppDataImplCopyWith<$Res> implements $AppDataCopyWith<$Res> {
  factory _$$AppDataImplCopyWith(
          _$AppDataImpl value, $Res Function(_$AppDataImpl) then) =
      __$$AppDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String backupSchemaVersion,
      DateTime backupTimestamp,
      List<Habit> habits,
      List<Reward> rewards,
      List<ClaimedReward> claimedRewards,
      List<Achievement> achievements,
      List<HabitStatus> habitStatuses,
      int userPoints});
}

/// @nodoc
class __$$AppDataImplCopyWithImpl<$Res>
    extends _$AppDataCopyWithImpl<$Res, _$AppDataImpl>
    implements _$$AppDataImplCopyWith<$Res> {
  __$$AppDataImplCopyWithImpl(
      _$AppDataImpl _value, $Res Function(_$AppDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backupSchemaVersion = null,
    Object? backupTimestamp = null,
    Object? habits = null,
    Object? rewards = null,
    Object? claimedRewards = null,
    Object? achievements = null,
    Object? habitStatuses = null,
    Object? userPoints = null,
  }) {
    return _then(_$AppDataImpl(
      backupSchemaVersion: null == backupSchemaVersion
          ? _value.backupSchemaVersion
          : backupSchemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      backupTimestamp: null == backupTimestamp
          ? _value.backupTimestamp
          : backupTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      habits: null == habits
          ? _value._habits
          : habits // ignore: cast_nullable_to_non_nullable
              as List<Habit>,
      rewards: null == rewards
          ? _value._rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<Reward>,
      claimedRewards: null == claimedRewards
          ? _value._claimedRewards
          : claimedRewards // ignore: cast_nullable_to_non_nullable
              as List<ClaimedReward>,
      achievements: null == achievements
          ? _value._achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as List<Achievement>,
      habitStatuses: null == habitStatuses
          ? _value._habitStatuses
          : habitStatuses // ignore: cast_nullable_to_non_nullable
              as List<HabitStatus>,
      userPoints: null == userPoints
          ? _value.userPoints
          : userPoints // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppDataImpl implements _AppData {
  const _$AppDataImpl(
      {required this.backupSchemaVersion,
      required this.backupTimestamp,
      required final List<Habit> habits,
      required final List<Reward> rewards,
      required final List<ClaimedReward> claimedRewards,
      required final List<Achievement> achievements,
      required final List<HabitStatus> habitStatuses,
      required this.userPoints})
      : _habits = habits,
        _rewards = rewards,
        _claimedRewards = claimedRewards,
        _achievements = achievements,
        _habitStatuses = habitStatuses;

  factory _$AppDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppDataImplFromJson(json);

  @override
  final String backupSchemaVersion;
  @override
  final DateTime backupTimestamp;
  final List<Habit> _habits;
  @override
  List<Habit> get habits {
    if (_habits is EqualUnmodifiableListView) return _habits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_habits);
  }

  final List<Reward> _rewards;
  @override
  List<Reward> get rewards {
    if (_rewards is EqualUnmodifiableListView) return _rewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewards);
  }

  final List<ClaimedReward> _claimedRewards;
  @override
  List<ClaimedReward> get claimedRewards {
    if (_claimedRewards is EqualUnmodifiableListView) return _claimedRewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_claimedRewards);
  }

  final List<Achievement> _achievements;
  @override
  List<Achievement> get achievements {
    if (_achievements is EqualUnmodifiableListView) return _achievements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_achievements);
  }

  final List<HabitStatus> _habitStatuses;
  @override
  List<HabitStatus> get habitStatuses {
    if (_habitStatuses is EqualUnmodifiableListView) return _habitStatuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_habitStatuses);
  }

// Logs for habit completions
// Assuming you track user points based on providers/points_provider.dart
  @override
  final int userPoints;

  @override
  String toString() {
    return 'AppData(backupSchemaVersion: $backupSchemaVersion, backupTimestamp: $backupTimestamp, habits: $habits, rewards: $rewards, claimedRewards: $claimedRewards, achievements: $achievements, habitStatuses: $habitStatuses, userPoints: $userPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppDataImpl &&
            (identical(other.backupSchemaVersion, backupSchemaVersion) ||
                other.backupSchemaVersion == backupSchemaVersion) &&
            (identical(other.backupTimestamp, backupTimestamp) ||
                other.backupTimestamp == backupTimestamp) &&
            const DeepCollectionEquality().equals(other._habits, _habits) &&
            const DeepCollectionEquality().equals(other._rewards, _rewards) &&
            const DeepCollectionEquality()
                .equals(other._claimedRewards, _claimedRewards) &&
            const DeepCollectionEquality()
                .equals(other._achievements, _achievements) &&
            const DeepCollectionEquality()
                .equals(other._habitStatuses, _habitStatuses) &&
            (identical(other.userPoints, userPoints) ||
                other.userPoints == userPoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      backupSchemaVersion,
      backupTimestamp,
      const DeepCollectionEquality().hash(_habits),
      const DeepCollectionEquality().hash(_rewards),
      const DeepCollectionEquality().hash(_claimedRewards),
      const DeepCollectionEquality().hash(_achievements),
      const DeepCollectionEquality().hash(_habitStatuses),
      userPoints);

  /// Create a copy of AppData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppDataImplCopyWith<_$AppDataImpl> get copyWith =>
      __$$AppDataImplCopyWithImpl<_$AppDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppDataImplToJson(
      this,
    );
  }
}

abstract class _AppData implements AppData {
  const factory _AppData(
      {required final String backupSchemaVersion,
      required final DateTime backupTimestamp,
      required final List<Habit> habits,
      required final List<Reward> rewards,
      required final List<ClaimedReward> claimedRewards,
      required final List<Achievement> achievements,
      required final List<HabitStatus> habitStatuses,
      required final int userPoints}) = _$AppDataImpl;

  factory _AppData.fromJson(Map<String, dynamic> json) = _$AppDataImpl.fromJson;

  @override
  String get backupSchemaVersion;
  @override
  DateTime get backupTimestamp;
  @override
  List<Habit> get habits;
  @override
  List<Reward> get rewards;
  @override
  List<ClaimedReward> get claimedRewards;
  @override
  List<Achievement> get achievements;
  @override
  List<HabitStatus> get habitStatuses; // Logs for habit completions
// Assuming you track user points based on providers/points_provider.dart
  @override
  int get userPoints;

  /// Create a copy of AppData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppDataImplCopyWith<_$AppDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
