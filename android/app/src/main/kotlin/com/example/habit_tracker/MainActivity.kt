package com.example.habit_tracker

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.habit_tracker.app/notifications" // Same name as in Dart

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleWeeklyNotification" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")
                    val weekday = call.argument<Int>("weekday") // Android Calendar weekday (Sun=1, Sat=7)

                    if (id != null && title != null && body != null && hour != null && minute != null && weekday != null) {
                       val scheduled = scheduleWeeklyNotification(id, title, body, hour, minute, weekday)
                       result.success(scheduled) // Return true if scheduled, false if permission missing
                    } else {
                        result.error("INVALID_ARGS", "Missing or invalid arguments for scheduleWeeklyNotification", null)
                    }
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id")
                    if (id != null) {
                        cancelNotification(id)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing id for cancelNotification", null)
                    }
                }
                 "requestPermission" -> {
                    val granted = requestNotificationPermission()
                     result.success(granted)
                 }
                 "scheduleDailyNotification" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")

                    if (id != null && title != null && body != null && hour != null && minute != null) {
                       val scheduled = scheduleDailyNotification(id, title, body, hour, minute)
                       result.success(scheduled)
                    } else {
                        result.error("INVALID_ARGS", "Missing or invalid arguments for scheduleDailyNotification", null)
                    }
                 }
                 "scheduleSpecificDateNotification" -> {
                     val id = call.argument<Int>("id")
                     val title = call.argument<String>("title")
                     val body = call.argument<String>("body")
                     val timestampMillis = call.argument<Long>("timestampMillis")

                     if (id != null && title != null && body != null && timestampMillis != null) {
                        val scheduled = scheduleSpecificDateNotification(id, title, body, timestampMillis)
                        result.success(scheduled)
                     } else {
                         result.error("INVALID_ARGS", "Missing or invalid arguments for scheduleSpecificDateNotification", null)
                     }
                 }
                 else -> {
                     result.notImplemented()
                 }
            }
         }
     }

     // --- Scheduling Methods ---

     private fun scheduleWeeklyNotification(id: Int, title: String, body: String, hour: Int, minute: Int, weekday: Int): Boolean {
         val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
         val intent = Intent(this, NotificationReceiver::class.java).apply {
            putExtra(NotificationReceiver.EXTRA_NOTIFICATION_ID, id)
            putExtra(NotificationReceiver.EXTRA_NOTIFICATION_TITLE, title)
            putExtra(NotificationReceiver.EXTRA_NOTIFICATION_BODY, body)
        }

        // Use the notification ID as the request code for PendingIntent to ensure uniqueness
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id, // Use notification ID as request code
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Calculate next trigger time
        val calendar = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_WEEK, weekday)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)

            // If the calculated time is in the past, add 7 days to schedule for the next week
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 7)
            }
        }

        // Check for exact alarm permission BEFORE attempting to schedule
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            println("Cannot schedule exact alarm for notification $id. SCHEDULE_EXACT_ALARM permission required and not granted.")
            return false // Indicate failure due to missing permission
        }

        try {
            // Proceed with scheduling the repeating alarm
            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                AlarmManager.INTERVAL_DAY * 7, // Repeat weekly
                 pendingIntent
             )
             // Enhanced logging
             val sdf = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z", java.util.Locale.getDefault())
             println("Scheduled weekly notification ID $id for weekday $weekday at $hour:$minute. Next trigger: ${sdf.format(calendar.time)} (Millis: ${calendar.timeInMillis})")
             return true // Indicate success
         } catch (e: SecurityException) {
             // This might still happen in rare cases even after the check, e.g., permission revoked between check and set.
             println("SecurityException: Could not schedule exact alarm for notification $id. ${e.message}")
             return false // Indicate failure
        } catch (e: Exception) {
             println("Error scheduling notification $id: ${e.message}")
              return false // Indicate failure
         }
     }

      private fun scheduleDailyNotification(id: Int, title: String, body: String, hour: Int, minute: Int): Boolean {
         val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
         val intent = Intent(this, NotificationReceiver::class.java).apply {
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_ID, id)
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_TITLE, title)
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_BODY, body)
         }
         val pendingIntent = PendingIntent.getBroadcast(
             this, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
         )

         // Calculate next trigger time for today or tomorrow
         val calendar = Calendar.getInstance().apply {
             set(Calendar.HOUR_OF_DAY, hour)
             set(Calendar.MINUTE, minute)
             set(Calendar.SECOND, 0)
             set(Calendar.MILLISECOND, 0)
             if (timeInMillis <= System.currentTimeMillis()) {
                 add(Calendar.DAY_OF_YEAR, 1) // If time passed today, schedule for tomorrow
             }
         }

         // Check permission
         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
             println("Cannot schedule exact alarm for daily notification $id. Permission required.")
             // Optionally use setInexactRepeating or return false
             // Using setInexactRepeating for daily might be acceptable
              try {
                  alarmManager.setInexactRepeating(
                      AlarmManager.RTC_WAKEUP,
                      calendar.timeInMillis,
                      AlarmManager.INTERVAL_DAY,
                      pendingIntent
                  )
                   println("Scheduled INEXACT daily notification ID $id at $hour:$minute, next trigger approx: ${calendar.timeInMillis}")
                   return true // Indicate success (even if inexact)
              } catch (e: Exception) {
                   println("Error scheduling inexact daily notification $id: ${e.message}")
                   return false
              }
         }

         // Schedule exact repeating daily alarm
         try {
             alarmManager.setRepeating(
                 AlarmManager.RTC_WAKEUP,
                 calendar.timeInMillis,
                 AlarmManager.INTERVAL_DAY, // Repeat daily
                 pendingIntent
             )
             println("Scheduled EXACT daily notification ID $id at $hour:$minute, next trigger: ${calendar.timeInMillis}")
             return true
         } catch (e: SecurityException) {
             println("SecurityException: Could not schedule exact daily alarm for notification $id. ${e.message}")
             return false
         } catch (e: Exception) {
             println("Error scheduling daily notification $id: ${e.message}")
             return false
         }
     }

      private fun scheduleSpecificDateNotification(id: Int, title: String, body: String, timestampMillis: Long): Boolean {
         val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
         val intent = Intent(this, NotificationReceiver::class.java).apply {
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_ID, id)
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_TITLE, title)
             putExtra(NotificationReceiver.EXTRA_NOTIFICATION_BODY, body)
         }
         val pendingIntent = PendingIntent.getBroadcast(
             this, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
         )

         // Check if the timestamp is in the past
         if (timestampMillis <= System.currentTimeMillis()) {
             println("Cannot schedule specific date notification $id because the time is in the past.")
             return false
         }

         // Check permission
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
             println("Cannot schedule exact alarm for specific date notification $id. Permission required.")
             // For specific dates, falling back to inexact is usually not desired. Return false.
             return false
         }

         // Schedule a one-time exact alarm
         try {
             alarmManager.setExactAndAllowWhileIdle(
                 AlarmManager.RTC_WAKEUP,
                 timestampMillis,
                 pendingIntent
             )
             println("Scheduled specific date notification ID $id for timestamp: $timestampMillis")
             return true
         } catch (e: SecurityException) {
             println("SecurityException: Could not schedule exact alarm for specific date notification $id. ${e.message}")
             return false
         } catch (e: Exception) {
             println("Error scheduling specific date notification $id: ${e.message}")
             return false
         }
     }


     // --- Cancellation & Permission ---

     private fun cancelNotification(id: Int) {
         val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NotificationReceiver::class.java) // Intent needs to match the one used for scheduling

        // Recreate the *exact same* PendingIntent used for scheduling
         val pendingIntent = PendingIntent.getBroadcast(
            this,
            id, // Use the same notification ID as request code
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE // Use same flags
        )

        alarmManager.cancel(pendingIntent)

        // Also cancel any potentially visible notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
         println("Cancelled notification ID $id")
    }

     private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // Android 13+
            val permission = android.Manifest.permission.POST_NOTIFICATIONS
            return if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
                 println("POST_NOTIFICATIONS permission already granted.")
                true
            } else {
                 println("Requesting POST_NOTIFICATIONS permission...")
                // Directly requesting here might not be ideal UX, usually triggered by UI action.
                // For simplicity in this context, we request directly.
                ActivityCompat.requestPermissions(this, arrayOf(permission), 101) // 101 is an arbitrary request code
                // NOTE: This function returns immediately after requesting.
                // The actual grant result comes in onRequestPermissionsResult.
                // For the purpose of this channel call, we might return false immediately
                // and let the Dart side handle re-checking later or guiding the user.
                false // Assume not granted until onRequestPermissionsResult confirms
            }
        } else {
             println("POST_NOTIFICATIONS permission not required for this Android version.")
            return true // Not needed for older versions
        }
    }

     // Optional: Handle permission result if needed for more complex logic
     // override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
     //     super.onRequestPermissionsResult(requestCode, permissions, grantResults)
     //     if (requestCode == 101) {
     //         if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
     //             println("POST_NOTIFICATIONS permission granted by user.")
     //             // Maybe send an event back to Dart?
     //         } else {
     //             println("POST_NOTIFICATIONS permission denied by user.")
     //             // Maybe send an event back to Dart?
     //         }
     //     }
     // }
}
