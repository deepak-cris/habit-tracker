import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // For ScaffoldMessenger
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Assuming Riverpod
import 'package:hive/hive.dart'; // Import Hive
import 'package:path_provider/path_provider.dart'; // Still needed for Hive path potentially
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // Optional sharing
import 'package:file_picker/file_picker.dart';

// Import your models
import '../models/app_data.dart';
import '../models/habit.dart';
import '../models/reward.dart';
import '../models/claimed_reward.dart';
import '../models/achievement.dart';
import '../models/habit_status.dart';
import '../providers/achievement_provider.dart'; // Needed for predefinedAchievements

// Import your providers (adjust paths and names as needed)
// These are used for EXPORT only. Import uses direct Hive access.
// Renamed to avoid conflicts if similar names are used elsewhere for UI state.
final _exportHabitListProvider = Provider<List<Habit>>(
  (ref) => Hive.box<Habit>(BackupService._habitBoxName).values.toList(),
);
final _exportRewardListProvider = Provider<List<Reward>>(
  (ref) => Hive.box<Reward>(BackupService._rewardBoxName).values.toList(),
);
final _exportClaimedRewardListProvider = Provider<List<ClaimedReward>>(
  (ref) =>
      Hive.box<ClaimedReward>(
        BackupService._claimedRewardBoxName,
      ).values.toList(),
);
// Exporting predefined achievements list
final _exportAchievementListProvider = Provider<List<Achievement>>(
  (ref) => predefinedAchievements, // Assumes this list is accessible
);
// HabitStatus is part of Habit model's dateStatus map, so no separate provider needed here for export
final _exportUserPointsProvider = Provider<int>(
  (ref) =>
      Hive.box(BackupService._userDataBoxName).get('points', defaultValue: 0),
);

// Provider for the service itself
final backupServiceProvider = Provider((ref) => BackupService(ref));

class BackupService {
  final Ref _ref; // Use WidgetRef or similar if calling from a widget

  // Define Hive box names (Adjust if your names are different)
  static const String _habitBoxName = 'habits';
  static const String _rewardBoxName = 'rewards';
  static const String _claimedRewardBoxName = 'claimed_rewards';
  static const String _userDataBoxName = 'user_data';
  // Add other box names if needed (e.g., for unlocked achievements if stored separately)
  // static const String _unlockedAchievementsBoxName = 'unlocked_achievements';

  BackupService(this._ref);

  Future<void> exportData(BuildContext context) async {
    // Pass context for ScaffoldMessenger
    // 1. Permission handling is implicitly managed by FilePicker.platform.saveFile via SAF.

    try {
      // 2. Fetch Data (using Riverpod ref - reading directly from Hive example)
      // Ensure boxes are open before reading. Consider opening them at app start.
      // It's safer to assume they might not be open and open them here.
      await Hive.openBox<Habit>(_habitBoxName);
      await Hive.openBox<Reward>(_rewardBoxName);
      await Hive.openBox<ClaimedReward>(_claimedRewardBoxName);
      await Hive.openBox(_userDataBoxName);
      // await Hive.openBox(_unlockedAchievementsBoxName); // If achievements stored separately

      final habits = _ref.read(_exportHabitListProvider);
      final rewards = _ref.read(_exportRewardListProvider);
      final claimedRewards = _ref.read(_exportClaimedRewardListProvider);
      final achievements = _ref.read(
        _exportAchievementListProvider,
      ); // Exporting predefined list
      final userPoints = _ref.read(_exportUserPointsProvider);
      // Habit statuses are within the Habit objects, no need to fetch separately

      // 3. Create AppData instance
      final appData = AppData(
        backupSchemaVersion: "1.0.0", // Start with version 1.0.0
        backupTimestamp: DateTime.now(),
        habits: habits,
        rewards: rewards,
        claimedRewards: claimedRewards,
        achievements: achievements, // Including all predefined achievements
        habitStatuses: [], // Not needed as separate list if part of Habit
        userPoints: userPoints,
      );

      // 4. Convert to JSON
      final jsonString = jsonEncode(appData.toJson());

      // 5. Use FilePicker to let user choose save location (SAF)
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Habit Tracker Backup',
        fileName: 'habit_tracker_backup_$timestamp.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: utf8.encode(jsonString), // Encode string to Uint8List
      );

      if (outputFile != null) {
        // FilePicker handled the saving using bytes
        _showSuccessSnackbar(context, 'Data export initiated successfully.');
        print("Data export initiated via FilePicker.");
      } else {
        // User canceled the file picker dialog
        _showInfoSnackbar(
          context,
          "Export cancelled: No save location selected.",
        );
      }
    } catch (e, stackTrace) {
      final errorMsg = "Error exporting data: $e";
      print("$errorMsg\n$stackTrace"); // Log stack trace for debugging
      _showErrorSnackbar(
        context,
        "Error exporting data. See console for details.",
      );
    }
  } // End of exportData function

  // --- Import Function ---
  Future<void> importData(BuildContext context) async {
    // 1. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      // 2. CONFIRMATION DIALOG (CRITICAL!)
      bool? confirmReplace = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // User must explicitly choose
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Confirm Import'),
            content: const Text(
              'WARNING: Importing will REPLACE ALL current habits, rewards, achievements, points, and related data. This action cannot be undone. Are you sure you want to proceed?',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Replace Data'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmReplace != true) {
        _showInfoSnackbar(context, "Import cancelled.");
        return; // User cancelled
      }

      // Proceed with import if confirmed
      _showInfoSnackbar(
        context,
        "Importing data... Please wait.",
      ); // Show progress indication
      try {
        // 3. Read File
        final jsonString = await file.readAsString();

        // 4. Parse JSON
        final jsonData = jsonDecode(jsonString);
        final appData = AppData.fromJson(jsonData);

        // Optional: Validate schema version if needed
        // if (appData.backupSchemaVersion != "1.0.0") {
        //   _showErrorSnackbar(context, "Backup file version mismatch. Cannot import.");
        //   return;
        // }

        // 5. Clear Existing Data
        await _clearAllUserData();
        print("Cleared existing user data.");

        // 6. Save Imported Data
        await _saveImportedData(appData);
        print("Saved imported user data.");

        // 7. Refresh UI (Crucial!)
        // Invalidation should happen *after* import completes, potentially back in the UI code
        // that called this importData function, or rely on Hive listeners if set up.
        // Removing incorrect invalidate calls from here.
        print("Data import complete. UI should refresh based on data changes.");

        // Add a small delay to allow state updates to potentially propagate before success message
        await Future.delayed(const Duration(milliseconds: 200));

        // 8. Notify User
        _showSuccessSnackbar(context, "Data imported successfully!");
      } catch (e, stackTrace) {
        // Handle errors (invalid file format, read error, save error)
        final errorMsg =
            "Error importing data: Invalid file format or error during processing.";
        print("Error importing data: $e\n$stackTrace");
        _showErrorSnackbar(context, errorMsg);
      }
    } else {
      // User canceled the picker
      _showInfoSnackbar(context, "No file selected.");
    }
  } // End of importData function

  // --- Implemented Data Handling Functions ---

  Future<void> _clearAllUserData() async {
    print("Attempting to clear user data...");
    try {
      // Open boxes before clearing
      final habitBox = await Hive.openBox<Habit>(_habitBoxName);
      final rewardBox = await Hive.openBox<Reward>(_rewardBoxName);
      final claimedRewardBox = await Hive.openBox<ClaimedReward>(
        _claimedRewardBoxName,
      );
      final userDataBox = await Hive.openBox(_userDataBoxName);
      // final unlockedAchievementsBox = await Hive.openBox(_unlockedAchievementsBoxName); // If used

      await habitBox.clear();
      print("Cleared $_habitBoxName box.");
      await rewardBox.clear();
      print("Cleared $_rewardBoxName box.");
      await claimedRewardBox.clear();
      print("Cleared $_claimedRewardBoxName box.");
      await userDataBox.clear(); // Clear all user data including points
      print("Cleared $_userDataBoxName box.");
      // await unlockedAchievementsBox.clear(); // If used
      // print("Cleared $_unlockedAchievementsBoxName box.");

      // Optionally close boxes if not needed immediately after
      // await habitBox.close();
      // await rewardBox.close();
      // await claimedRewardBox.close();
      // await userDataBox.close();
    } catch (e, stackTrace) {
      print("Error clearing user data: $e\n$stackTrace");
      // Rethrow or handle as needed, maybe notify user
      throw Exception("Failed to clear existing data: $e");
    }
  }

  Future<void> _saveImportedData(AppData data) async {
    print("Attempting to save imported data...");
    try {
      // Open boxes before writing
      final habitBox = await Hive.openBox<Habit>(_habitBoxName);
      final rewardBox = await Hive.openBox<Reward>(_rewardBoxName);
      final claimedRewardBox = await Hive.openBox<ClaimedReward>(
        _claimedRewardBoxName,
      );
      final userDataBox = await Hive.openBox(_userDataBoxName);
      // final unlockedAchievementsBox = await Hive.openBox(_unlockedAchievementsBoxName); // If used

      // Use putAll for potentially better performance with maps
      await habitBox.putAll(
        Map.fromEntries(data.habits.map((h) => MapEntry(h.id, h))),
      );
      print("Saved ${data.habits.length} habits.");
      await rewardBox.putAll(
        Map.fromEntries(data.rewards.map((r) => MapEntry(r.id, r))),
      );
      print("Saved ${data.rewards.length} rewards.");
      await claimedRewardBox.putAll(
        Map.fromEntries(data.claimedRewards.map((cr) => MapEntry(cr.id, cr))),
      );
      print("Saved ${data.claimedRewards.length} claimed rewards.");
      await userDataBox.put('points', data.userPoints);
      print("Saved user points: ${data.userPoints}.");

      // How to handle achievements depends on whether they are predefined or user-specific
      // If achievements are predefined and we only track unlocked IDs:
      // await unlockedAchievementsBox.clear(); // Clear existing unlocked
      // await unlockedAchievementsBox.addAll(data.unlockedAchievementIds); // Assuming AppData has this field
      // print("Saved unlocked achievement IDs.");

      // If achievements included in AppData are the definitions (like in export):
      // No action needed here if they are predefined constants in the app.

      // HabitStatus is saved as part of the Habit object's dateStatus map.

      // Optionally close boxes
      // await habitBox.close();
      // await rewardBox.close();
      // await claimedRewardBox.close();
      // await userDataBox.close();
    } catch (e, stackTrace) {
      print("Error saving imported data: $e\n$stackTrace");
      // Rethrow or handle as needed, maybe notify user
      throw Exception("Failed to save imported data: $e");
    }
  }

  // --- Helper Snackbar Functions ---
  void _showSuccessSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showInfoSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
} // End of BackupService class
