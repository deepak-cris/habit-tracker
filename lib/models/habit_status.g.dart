// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitStatusAdapter extends TypeAdapter<HabitStatus> {
  @override
  final int typeId = 1;

  @override
  HabitStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitStatus.none;
      case 1:
        return HabitStatus.done;
      case 2:
        return HabitStatus.fail;
      case 3:
        return HabitStatus.skip;
      default:
        return HabitStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, HabitStatus obj) {
    switch (obj) {
      case HabitStatus.none:
        writer.writeByte(0);
        break;
      case HabitStatus.done:
        writer.writeByte(1);
        break;
      case HabitStatus.fail:
        writer.writeByte(2);
        break;
      case HabitStatus.skip:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
