import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final pointsProvider = StateNotifierProvider<PointsNotifier, int>((ref) {
  return PointsNotifier();
});

class PointsNotifier extends StateNotifier<int> {
  PointsNotifier() : super(0) {
    _loadPoints(); // Load points when notifier is first created
  }

  static const String _boxName = 'userProfile';
  static const String _pointsKey = 'userPoints';

  Future<void> _loadPoints() async {
    try {
      final box = await Hive.openBox(_boxName);
      // Load points, default to 0 if not found
      state = box.get(_pointsKey, defaultValue: 0) as int;
      // Don't close the box here if other notifiers might use it
    } catch (e) {
      print("Error loading points from Hive: $e");
      state = 0; // Default to 0 on error
    }
  }

  Future<void> _savePoints() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_pointsKey, state);
    } catch (e) {
      print("Error saving points to Hive: $e");
    }
  }

  void addPoints(int amount) {
    if (amount <= 0) return;
    state = state + amount;
    _savePoints();
    print("Added $amount points. New total: $state"); // Debug print
  }

  // Returns true if points were successfully spent, false otherwise
  bool spendPoints(int amount) {
    if (amount <= 0) return false;
    if (state >= amount) {
      state = state - amount;
      _savePoints();
      print("Spent $amount points. Remaining: $state"); // Debug print
      return true;
    } else {
      print(
        "Not enough points to spend $amount. Current: $state",
      ); // Debug print
      return false; // Not enough points
    }
  }

  // Optional: Method to reset points (for testing or specific features)
  void resetPoints() {
    state = 0;
    _savePoints();
  }
}
