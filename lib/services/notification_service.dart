import 'package:flutter/material.dart'; // Keep for TimeOfDay
import 'package:flutter/services.dart'; // Import for MethodChannel
import '../models/habit.dart'; // Assuming Habit model is here

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  // Platform Channel setup
  static const platform = MethodChannel('com.habit_tracker.app/notifications');

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  // No need for FlutterLocalNotificationsPlugin instance anymore
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // No need for plugin initialization or timezone config here
    // Request permission via platform channel
    try {
      final bool? granted = await platform.invokeMethod('requestPermission');
      print("Android Notification Permission Granted via Channel: $granted");
      if (granted == false) {
        // Handle permission denial - maybe show a message in the UI later
        print("Notification permission was denied or not yet granted.");
      }
    } on PlatformException catch (e) {
      print("Failed to request notification permission: '${e.message}'.");
    }
    print("Notification Service Initialized (using Platform Channel)");
  }

  // Timezone configuration is no longer needed here as native code uses device time
  // Future<void> _configureLocalTimeZone() async { ... }

  // Permission request is now handled in init() via platform channel
  // Future<void> _requestAndroidPermissions() async { ... }

  // --- Scheduling Logic (using Platform Channel) ---

  Future<void> scheduleHabitReminders(Habit habit) async {
    // Cancel reminders first (now uses platform channel)
    await cancelHabitReminders(habit.id);

    if (habit.reminderTimes == null || habit.reminderTimes!.isEmpty) {
      print("No reminders to schedule for habit: ${habit.name}");
      return;
    }

    print(
      "Scheduling reminders for habit via Platform Channel: ${habit.name} (Type: ${habit.reminderScheduleType})",
    );

    // --- Handle Specific Date Scheduling ---
    if (habit.reminderScheduleType == 'specific_date') {
      if (habit.reminderSpecificDateTime != null) {
        final notificationId = _generateNotificationId(
          habit.id,
          0,
        ); // Use index 0 for specific date
        final timestampMillis =
            habit.reminderSpecificDateTime!.millisecondsSinceEpoch;
        String notificationBody =
            'Reminder for: ${habit.name}'; // Simple body for specific date

        try {
          print(
            "Invoking scheduleSpecificDateNotification: ID=$notificationId, Timestamp=$timestampMillis",
          );
          final bool? scheduled = await platform
              .invokeMethod<bool>('scheduleSpecificDateNotification', {
                'id': notificationId,
                'title': 'Habit Reminder',
                'body': notificationBody,
                'timestampMillis': timestampMillis,
              });

          if (scheduled == true) {
            print(
              "Successfully scheduled specific date notification $notificationId.",
            );
          } else {
            print(
              "WARNING: Failed to schedule specific date notification $notificationId. Time might be in the past or 'Alarms & reminders' permission is required.",
            );
          }
        } on PlatformException catch (e) {
          print(
            "PlatformException while scheduling specific date notification $notificationId: '${e.message}'.",
          );
        } catch (e) {
          print(
            "Error scheduling specific date notification $notificationId: $e",
          );
        }
      } else {
        print(
          "Skipping specific date scheduling for ${habit.name}: reminderSpecificDateTime is null.",
        );
      }
      return; // Stop here for specific date type
    }

    // --- Handle Daily or Weekly Scheduling ---
    if (habit.reminderScheduleType == 'daily' ||
        habit.reminderScheduleType == 'weekly') {
      if (habit.reminderTimes == null || habit.reminderTimes!.isEmpty) {
        print(
          "No reminder times set for daily/weekly schedule for habit: ${habit.name}",
        );
        return;
      }

      for (int i = 0; i < habit.reminderTimes!.length; i++) {
        final reminderMap = habit.reminderTimes![i];
        final reminderTime = TimeOfDay(
          hour: reminderMap['hour'] as int,
          minute: reminderMap['minute'] as int,
        );
        final reminderNote = reminderMap['note'] as String?;
        final notificationId = _generateNotificationId(habit.id, i);
        String notificationBody = 'Time for your habit: ${habit.name}';
        if (reminderNote != null && reminderNote.isNotEmpty) {
          notificationBody += '\n$reminderNote';
        }

        if (habit.reminderScheduleType == 'daily') {
          // --- Schedule Daily ---
          try {
            print(
              "Invoking scheduleDailyNotification: ID=$notificationId, Time=${reminderTime.hour}:${reminderTime.minute}",
            );
            final bool? scheduled = await platform
                .invokeMethod<bool>('scheduleDailyNotification', {
                  'id': notificationId,
                  'title': 'Habit Reminder',
                  'body': notificationBody,
                  'hour': reminderTime.hour,
                  'minute': reminderTime.minute,
                });
            if (scheduled == true) {
              print(
                "Successfully scheduled daily notification $notificationId.",
              );
            } else {
              print(
                "WARNING: Failed to schedule daily notification $notificationId. 'Alarms & reminders' permission might be required for exact timing.",
              );
            }
          } on PlatformException catch (e) {
            print(
              "PlatformException while scheduling daily notification $notificationId: '${e.message}'.",
            );
          } catch (e) {
            print("Error scheduling daily notification $notificationId: $e");
          }
        } else {
          // --- Schedule Weekly ---
          // Schedule based on selected days (habit.selectedDays should be valid for weekly type)
          if (habit.selectedDays.length == 7) {
            for (
              int dayIndex = 0;
              dayIndex < habit.selectedDays.length;
              dayIndex++
            ) {
              if (habit.selectedDays[dayIndex]) {
                final androidWeekday =
                    (dayIndex % 7) + 1; // Convert 0-6 to 1-7 (Sun-Sat)
                try {
                  print(
                    "Invoking scheduleWeeklyNotification: ID=$notificationId, Weekday=$androidWeekday, Time=${reminderTime.hour}:${reminderTime.minute}",
                  );
                  final bool? scheduled = await platform
                      .invokeMethod<bool>('scheduleWeeklyNotification', {
                        'id': notificationId,
                        'title': 'Habit Reminder',
                        'body': notificationBody,
                        'hour': reminderTime.hour,
                        'minute': reminderTime.minute,
                        'weekday': androidWeekday,
                      });

                  if (scheduled == true) {
                    print(
                      "Successfully scheduled weekly notification $notificationId for day $androidWeekday.",
                    );
                  } else {
                    print(
                      "WARNING: Failed to schedule weekly notification $notificationId for day $androidWeekday. 'Alarms & reminders' permission might be required.",
                    );
                  }
                } on PlatformException catch (e) {
                  print(
                    "PlatformException while scheduling weekly notification $notificationId for day $androidWeekday: '${e.message}'.",
                  );
                } catch (e) {
                  print(
                    "Error scheduling weekly notification $notificationId for day $androidWeekday: $e",
                  );
                }
              }
            }
          } else {
            print(
              "Skipping weekly scheduling for ${habit.name}: selectedDays list is invalid.",
            );
          }
        }
      }
    } else if (habit.reminderScheduleType != 'none') {
      print(
        "Unknown reminderScheduleType '${habit.reminderScheduleType}' for habit: ${habit.name}",
      );
    }
  }

  // Helper _nextInstanceOfTime is no longer needed as calculation happens natively

  // --- Cancellation Logic (using Platform Channel) ---

  Future<void> cancelHabitReminders(String habitId) async {
    print(
      "Attempting to cancel reminders for habit ID: $habitId via Platform Channel",
    );
    // Iterate through potential reminder indices to generate IDs to cancel
    // Assuming a maximum of 10 reminders per habit for cancellation purposes
    int cancelCount = 0;
    for (int i = 0; i < 10; i++) {
      // Assume max 10 reminders
      final notificationId = _generateNotificationId(habitId, i);
      try {
        await platform.invokeMethod('cancelNotification', {
          'id': notificationId,
        });
        // We don't know for sure if this specific ID existed, but we attempt cancellation
        // Native side handles non-existent alarms gracefully.
        cancelCount++; // Increment count for attempted cancellations
      } on PlatformException catch (e) {
        // Log error but continue trying other potential IDs
        print(
          "Failed to cancel notification $notificationId: '${e.message}'. May not have existed.",
        );
      } catch (e) {
        print("Error cancelling notification $notificationId: $e");
      }
    }
    print(
      "Attempted cancellation for $cancelCount potential notification IDs for habit: $habitId",
    );
    // Note: This doesn't confirm they were actually active, just that the cancel call was made.
  }

  Future<void> cancelAllNotifications() async {
    // Option 1: Implement a native 'cancelAll' method (cleaner)
    // try {
    //   await platform.invokeMethod('cancelAllNotifications');
    //   print("Invoked cancelAllNotifications via Platform Channel.");
    // } on PlatformException catch (e) {
    //   print("Failed to cancel all notifications: '${e.message}'.");
    // }

    // Option 2: If no native 'cancelAll', we can't reliably cancel all from Dart
    // without knowing all possible habit IDs.
    print(
      "Warning: cancelAllNotifications called, but not implemented via platform channel yet. Native implementation needed.",
    );
    // For now, this function won't do anything effective across all habits.
  }

  // --- Unique Notification ID Generation (Keep this logic) ---
  // Generates a predictable ID based on habit ID and reminder index.
  // IMPORTANT: Assumes habit ID is stable. Uses String hashcode which might have collisions,
  // but is usually sufficient for this scale. A more robust unique ID might be needed for production.
  // We use a large offset to minimize collision chances with other potential notification sources.
  int _generateNotificationId(String habitId, int reminderIndex) {
    // Combine hash codes. Using bitwise XOR and shifting can help distribute IDs.
    // Ensure the result fits within a 32-bit signed integer range for Android compatibility.
    int baseHash = habitId.hashCode;
    int combinedHash =
        baseHash ^ (reminderIndex + 1) * 31; // Simple combination
    return combinedHash & 0x7FFFFFFF; // Ensure positive 32-bit int
  }

  // Helper _isNotificationForHabit is no longer needed as cancellation is done by ID natively.

  // Callbacks like onDidReceiveLocalNotification / onDidReceiveNotificationResponse
  // are specific to flutter_local_notifications and are removed.
  // Handling notification taps would require setting up a PendingIntent on the native side
  // that launches the Flutter app, potentially with data in the Intent to navigate.
  // This is currently not implemented in the native code provided.
}
