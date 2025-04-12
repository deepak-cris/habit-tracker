import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../models/reward.dart';
import 'points_provider.dart'; // To interact with points
import 'claimed_reward_provider.dart'; // To add claimed rewards

final rewardProvider = StateNotifierProvider<RewardNotifier, List<Reward>>((
  ref,
) {
  return RewardNotifier(ref);
});

class RewardNotifier extends StateNotifier<List<Reward>> {
  final Ref _ref; // Keep ref to read other providers
  RewardNotifier(this._ref) : super([]) {
    _loadRewards();
  }

  static const String _boxName = 'rewards';
  final _uuid = const Uuid();

  Future<void> _loadRewards() async {
    try {
      final box = await Hive.openBox<Reward>(_boxName);
      // Filter out any potential nulls just in case
      state =
          box.values.where((reward) => reward != null).toList().cast<Reward>();
      // Sort rewards? Maybe by cost or name? Optional.
      // state.sort((a, b) => a.pointCost.compareTo(b.pointCost));
    } catch (e) {
      print("Error loading rewards from Hive: $e");
      state = [];
    }
  }

  Future<void> _saveReward(Reward reward) async {
    try {
      final box = await Hive.openBox<Reward>(_boxName);
      await box.put(reward.id, reward); // Use reward ID as key
    } catch (e) {
      print("Error saving reward ${reward.id} to Hive: $e");
    }
  }

  Future<void> _deleteRewardFromBox(String rewardId) async {
    try {
      final box = await Hive.openBox<Reward>(_boxName);
      await box.delete(rewardId);
    } catch (e) {
      print("Error deleting reward $rewardId from Hive: $e");
    }
  }

  void addReward({
    required String name,
    String? description,
    required int pointCost,
    int? iconCodePoint,
  }) {
    final newReward = Reward(
      id: _uuid.v4(), // Generate unique ID
      name: name,
      description: description,
      pointCost: pointCost,
      iconCodePoint: iconCodePoint,
    );
    state = [...state, newReward];
    _saveReward(newReward);
  }

  void editReward(Reward updatedReward) {
    state = [
      for (final reward in state)
        if (reward.id == updatedReward.id) updatedReward else reward,
    ];
    _saveReward(updatedReward);
  }

  void deleteReward(String rewardId) {
    state = state.where((reward) => reward.id != rewardId).toList();
    _deleteRewardFromBox(rewardId);
  }

  // Returns true if reward was successfully claimed, false otherwise
  bool claimReward(String rewardId, String? reason) {
    final rewardIndex = state.indexWhere((r) => r.id == rewardId);
    if (rewardIndex == -1) return false; // Reward not found

    final reward = state[rewardIndex];

    // Attempt to spend points
    final bool success = _ref
        .read(pointsProvider.notifier)
        .spendPoints(reward.pointCost);

    if (success) {
      // Add to claimed rewards list
      _ref.read(claimedRewardProvider.notifier).addClaim(reward, reason);
      print("Claimed reward: ${reward.name}"); // Debug print
      return true;
    } else {
      print(
        "Failed to claim reward: ${reward.name} (not enough points)",
      ); // Debug print
      return false;
    }
  }
}
