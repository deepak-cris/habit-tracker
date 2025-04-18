// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      dateStatus: (fields[2] as Map).cast<DateTime, HabitStatus>(),
      notes: (fields[4] as Map).cast<DateTime, String>(),
      description: fields[5] as String?,
      reasons: (fields[6] as List).cast<String>(),
      startDate: fields[7] as DateTime,
      scheduleType: fields[8] as String,
      selectedDays: (fields[9] as List).cast<bool>(),
      targetStreak: fields[3] as int,
      isMastered: fields[10] as bool,
      reminderTimes: (fields[11] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      reminderScheduleType: fields[12] as String,
      reminderSpecificDateTime: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dateStatus)
      ..writeByte(3)
      ..write(obj.targetStreak)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.reasons)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.scheduleType)
      ..writeByte(9)
      ..write(obj.selectedDays)
      ..writeByte(10)
      ..write(obj.isMastered)
      ..writeByte(11)
      ..write(obj.reminderTimes)
      ..writeByte(12)
      ..write(obj.reminderScheduleType)
      ..writeByte(13)
      ..write(obj.reminderSpecificDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      dateStatus: _dateTimeHabitStatusMapFromJson(
          json['dateStatus'] as Map<String, dynamic>),
      notes: _dateTimeStringMapFromJson(json['notes'] as Map<String, dynamic>),
      description: json['description'] as String?,
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      startDate: DateTime.parse(json['startDate'] as String),
      scheduleType: json['scheduleType'] as String? ?? 'Fixed',
      selectedDays: (json['selectedDays'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      targetStreak: (json['targetStreak'] as num?)?.toInt() ?? 21,
      isMastered: json['isMastered'] as bool? ?? false,
      reminderTimes: (json['reminderTimes'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      reminderScheduleType: json['reminderScheduleType'] as String? ?? 'weekly',
      reminderSpecificDateTime: json['reminderSpecificDateTime'] == null
          ? null
          : DateTime.parse(json['reminderSpecificDateTime'] as String),
    );

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'dateStatus': _dateTimeHabitStatusMapToJson(instance.dateStatus),
      'targetStreak': instance.targetStreak,
      'notes': _dateTimeStringMapToJson(instance.notes),
      'description': instance.description,
      'reasons': instance.reasons,
      'startDate': instance.startDate.toIso8601String(),
      'scheduleType': instance.scheduleType,
      'selectedDays': instance.selectedDays,
      'isMastered': instance.isMastered,
      'reminderTimes': instance.reminderTimes,
      'reminderScheduleType': instance.reminderScheduleType,
      'reminderSpecificDateTime':
          instance.reminderSpecificDateTime?.toIso8601String(),
    };
