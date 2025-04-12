import 'package:hive/hive.dart';

part 'claimed_reward.g.dart';

@HiveType(typeId: 3) // Unique typeId
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
}
