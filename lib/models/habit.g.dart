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
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.reminderTimes);
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
