import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart'; // Added

part 'claimed_reward.g.dart';

@HiveType(typeId: 3) // Unique typeId
@JsonSerializable() // Added
class ClaimedReward extends HiveObject {
  @HiveField(0)
  final String id; // Unique ID for this claim instance

  @HiveField(1)
  final String rewardId; // ID of the Reward claimed

  @HiveField(2)
  final String rewardName; // Store name for display even if reward is deleted

  @HiveField(3)
  final int pointCost; // Store cost for historical purposes

  @HiveField(4)
  final String? claimReason; // Optional reason for claiming

  @HiveField(5)
  final DateTime claimTimestamp; // When it was claimed

  ClaimedReward({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.pointCost,
    this.claimReason,
    required this.claimTimestamp,
  });

  // Factory constructor for JSON deserialization
  factory ClaimedReward.fromJson(Map<String, dynamic> json) =>
      _$ClaimedRewardFromJson(json);

  // Method for JSON serialization
  Map<String, dynamic> toJson() => _$ClaimedRewardToJson(this);
}
