import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // Import uuid package
import '../models/reward.dart';
import '../models/claimed_reward.dart'; // Import the ClaimedReward model

final claimedRewardProvider =
    StateNotifierProvider<ClaimedRewardNotifier, List<ClaimedReward>>((ref) {
      return ClaimedRewardNotifier();
    });

class ClaimedRewardNotifier extends StateNotifier<List<ClaimedReward>> {
  ClaimedRewardNotifier() : super([]) {
    _loadClaimedRewards();
  }

  static const String _boxName = 'claimedRewards';

  Future<void> _loadClaimedRewards() async {
    try {
      final box = await Hive.openBox<ClaimedReward>(_boxName);
      state = box.values.toList().cast<ClaimedReward>();
      // Optional: Sort by claim date (most recent first)
      state.sort((a, b) => b.claimTimestamp.compareTo(a.claimTimestamp));
    } catch (e) {
      print("Error loading claimed rewards from Hive: $e");
      state = [];
    }
  }

  Future<void> _saveClaimedReward(ClaimedReward claimedReward) async {
    try {
      final box = await Hive.openBox<ClaimedReward>(_boxName);
      await box.put(claimedReward.id, claimedReward);
    } catch (e) {
      print("Error saving claimed reward to Hive: $e");
    }
  }

  void addClaim(Reward reward, String? reason) {
    final newClaim = ClaimedReward(
      id: const Uuid().v4(),
      rewardId: reward.id,
      rewardName: reward.name,
      pointCost: reward.pointCost,
      claimReason: reason,
      claimTimestamp: DateTime.now(),
    );
    state = [
      newClaim,
      ...state,
    ]; // Add to the beginning for reverse chronological order
    _saveClaimedReward(newClaim);
  }

  // Method to clear all claimed rewards
  Future<void> clearHistory() async {
    try {
      final box = await Hive.openBox<ClaimedReward>(_boxName);
      await box.clear(); // Clear all entries from the box
      state = []; // Update the state to an empty list
      print("Claimed reward history cleared.");
    } catch (e) {
      print("Error clearing claimed reward history: $e");
      // Optionally, handle the error (e.g., show a message to the user)
      // For now, we just print the error.
      // We might want to reload the state from the box in case of error,
      // but if clear() failed partially, the state might be inconsistent.
      // Setting state to empty might be safer, assuming the user wants it cleared.
      state = [];
    }
  }
}
