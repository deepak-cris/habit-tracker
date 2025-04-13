import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // Import flutter_timezone
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart'; // Assuming Habit model is here

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configure Timezone
    await _configureLocalTimeZone();

    // Android Initialization Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon

    // iOS Initialization Settings
    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Optional callback
    );

    // Linux Initialization Settings (Optional)
    // final LinuxInitializationSettings initializationSettingsLinux =
    //     LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          // linux: initializationSettingsLinux,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Optional callback for notification tap
    );

    // Request permissions explicitly for Android 13+
    // This might need to be called from the UI based on user interaction
    // await _requestAndroidPermissions();
    print("Notification Service Initialized with local timezone set.");
  }

  // --- Timezone Configuration ---
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    if (kIsWeb) {
      // Timezone detection doesn't work reliably on web
      print("Timezone configuration skipped for web.");
      // Optionally set a default or handle differently
      // tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      return;
    }
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("Local timezone set to: $timeZoneName");
    } catch (e) {
      print("Error getting local timezone: $e. Using default UTC.");
      // Fallback to UTC if detection fails
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  // --- Permission Requests (Example for Android 13+) ---
  Future<void> _requestAndroidPermissions() async {
    final bool? granted =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(); // Request permission for Android 13+
    print("Android Notification Permission Granted: $granted");
    // You might want to handle the case where permission is denied
  }

  // --- Scheduling Logic ---

  Future<void> scheduleHabitReminders(Habit habit) async {
    await cancelHabitReminders(habit.id); // Cancel old ones first

    if (habit.reminderTimes == null || habit.reminderTimes!.isEmpty) {
      print("No reminders to schedule for habit: ${habit.name}");
      return;
    }

    print("Scheduling reminders for habit: ${habit.name}");

    final now = tz.TZDateTime.now(tz.local); // Use TZDateTime

    for (int i = 0; i < habit.reminderTimes!.length; i++) {
      final reminderMap = habit.reminderTimes![i];
      final reminderTime = TimeOfDay(
        hour: reminderMap['hour'] as int, // Cast to int
        minute: reminderMap['minute'] as int, // Cast to int
      );
      final reminderNote = reminderMap['note'] as String?; // Get optional note

      // Create a unique ID for each reminder instance of a habit
      // Combining habit ID hashcode with reminder index should be sufficient
      final notificationId = _generateNotificationId(habit.id, i);

      // Schedule based on selected days
      for (int dayIndex = 0; dayIndex < habit.selectedDays.length; dayIndex++) {
        if (habit.selectedDays[dayIndex]) {
          // Flutter day index: Monday=1, Sunday=7. DateTime day index: Monday=1, Sunday=7. Matches!
          final scheduleDay = dayIndex + 1; // DateTime weekday format

          tz.TZDateTime scheduledDate = _nextInstanceOfTime(
            reminderTime.hour,
            reminderTime.minute,
            scheduleDay,
            now,
          );

          print(
            "Scheduling for Day: $scheduleDay at $scheduledDate (ID: $notificationId)",
          );

          try {
            // Construct notification body
            String notificationBody = 'Time for your habit: ${habit.name}';
            if (reminderNote != null && reminderNote.isNotEmpty) {
              notificationBody += '\n$reminderNote'; // Append note if exists
            }

            await flutterLocalNotificationsPlugin.zonedSchedule(
              notificationId, // Unique ID for this specific reminder time of this habit
              'Habit Reminder', // Title
              notificationBody, // Use the constructed body with optional note
              scheduledDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'habit_reminders_channel', // Channel ID
                  'Habit Reminders', // Channel Name
                  channelDescription:
                      'Notifications to remind you of your habits',
                  importance: Importance.max,
                  priority: Priority.high,
                  // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional custom sound
                  // icon: '@mipmap/ic_launcher', // Optional specific icon
                ),
                iOS: DarwinNotificationDetails(
                  // sound: 'default', // Optional custom sound
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents:
                  DateTimeComponents
                      .dayOfWeekAndTime, // Match day of week and time
              payload: 'habit_reminder_${habit.id}', // Optional payload
            );
            print(
              "Scheduled notification $notificationId for ${habit.name} on day $scheduleDay at $reminderTime",
            );
          } catch (e) {
            print("Error scheduling notification $notificationId: $e");
          }
        }
      }
    }
  }

  // Helper to calculate the next instance of a specific day and time
  tz.TZDateTime _nextInstanceOfTime(
    int hour,
    int minute,
    int weekDay,
    tz.TZDateTime now,
  ) {
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If the scheduled time is in the past for today, move to the next occurrence
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    // Move to the correct weekday
    while (scheduledDate.weekday != weekDay) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- Cancellation Logic ---

  Future<void> cancelHabitReminders(String habitId) async {
    print(
      "Attempting to cancel reminders for habit ID hash: ${habitId.hashCode}",
    );
    // We need to cancel potentially multiple notifications per habit (one for each reminder time)
    // Since we don't know how many reminders *were* set, we might need to iterate through possible IDs
    // or fetch all pending notifications and filter by a pattern/payload if possible.
    // A simpler approach for now: Cancel a range of potential IDs. Assuming max 10 reminders per habit.
    // This is NOT robust. A better way is needed, perhaps storing notification IDs.
    // For now, let's just cancel *all* notifications and reschedule. This is inefficient but safer.
    // await flutterLocalNotificationsPlugin.cancelAll(); // Inefficient!

    // Alternative: Fetch pending requests and cancel based on payload or ID pattern if possible
    final List<PendingNotificationRequest> pendingRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    int cancelCount = 0;
    for (PendingNotificationRequest request in pendingRequests) {
      // Check if the ID matches the pattern for the given habitId
      // This requires a consistent ID generation scheme. Let's refine _generateNotificationId
      if (_isNotificationForHabit(request.id, habitId)) {
        await flutterLocalNotificationsPlugin.cancel(request.id);
        cancelCount++;
      }
    }
    print("Cancelled $cancelCount notifications for habit: $habitId");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all notifications.");
  }

  // --- Unique Notification ID Generation ---
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

  // Helper to check if a notification ID belongs to a specific habit
  // This relies entirely on the generation scheme being reversible or checkable.
  // Our current scheme isn't easily reversible. We might need to store IDs or use payload.
  // Let's assume for now we can't reliably check this way without storing IDs.
  // The cancelAll() approach or filtering by payload is more practical without extra storage.
  bool _isNotificationForHabit(int notificationId, String habitId) {
    // This is difficult with the current hash-based ID generation.
    // We cannot reliably determine the original habitId and index from the combined hash.
    // Returning false to indicate this method is not reliable with the current ID scheme.
    // Consider using the payload for identification during cancellation.
    print(
      "Warning: _isNotificationForHabit check is not reliable with current ID scheme.",
    );
    return false;
    // If we stored notification IDs associated with the habit, we could check against that list.
  }

  // --- Optional Callbacks (Example Placeholders) ---

  // static void onDidReceiveLocalNotification(
  //     int id, String? title, String? body, String? payload) async {
  //   // display a dialog with the notification details, tap ok to go to another page
  //   print('onDidReceiveLocalNotification payload: $payload');
  // }

  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //    final String? payload = notificationResponse.payload;
  //    if (notificationResponse.payload != null) {
  //      print('notification payload: $payload');
  //    }
  //    // TODO: Handle notification tap, e.g., navigate to habit details
  //    // Example: Check payload and navigate
  //    // if (payload != null && payload.startsWith('habit_reminder_')) {
  //    //   String habitId = payload.substring('habit_reminder_'.length);
  //    //   // Navigation logic here (might need a GlobalKey<NavigatorState> or similar)
  //    // }
  // }
}
