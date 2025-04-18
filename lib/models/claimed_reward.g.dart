// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claimed_reward.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClaimedRewardAdapter extends TypeAdapter<ClaimedReward> {
  @override
  final int typeId = 3;

  @override
  ClaimedReward read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClaimedReward(
      id: fields[0] as String,
      rewardId: fields[1] as String,
      rewardName: fields[2] as String,
      pointCost: fields[3] as int,
      claimReason: fields[4] as String?,
      claimTimestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ClaimedReward obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rewardId)
      ..writeByte(2)
      ..write(obj.rewardName)
      ..writeByte(3)
      ..write(obj.pointCost)
      ..writeByte(4)
      ..write(obj.claimReason)
      ..writeByte(5)
      ..write(obj.claimTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimedRewardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimedReward _$ClaimedRewardFromJson(Map<String, dynamic> json) =>
    ClaimedReward(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      rewardName: json['rewardName'] as String,
      pointCost: (json['pointCost'] as num).toInt(),
      claimReason: json['claimReason'] as String?,
      claimTimestamp: DateTime.parse(json['claimTimestamp'] as String),
    );

Map<String, dynamic> _$ClaimedRewardToJson(ClaimedReward instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rewardId': instance.rewardId,
      'rewardName': instance.rewardName,
      'pointCost': instance.pointCost,
      'claimReason': instance.claimReason,
      'claimTimestamp': instance.claimTimestamp.toIso8601String(),
    };
