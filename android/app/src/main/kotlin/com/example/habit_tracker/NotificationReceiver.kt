package com.example.habit_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.PendingIntent // Import PendingIntent

class NotificationReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "habit_reminders_channel" // Keep only one declaration
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_BODY = "notification_body"
        const val EXTRA_HABIT_ID = "habit_id" // Key for habit ID extra
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
        val title = intent.getStringExtra(EXTRA_NOTIFICATION_TITLE) ?: "Habit Reminder"
        val body = intent.getStringExtra(EXTRA_NOTIFICATION_BODY) ?: "Time for your habit!"
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) // Extract habitId

        createNotificationChannel(context)

        // Create Intent to launch MainActivity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP // Standard flags
            action = Intent.ACTION_MAIN // Define action to prevent issues on some devices
            addCategory(Intent.CATEGORY_LAUNCHER) // Define category
            if (habitId != null) {
                putExtra(EXTRA_HABIT_ID, habitId) // Pass habitId to MainActivity
            }
        }

        // Create PendingIntent for notification tap
        val contentPendingIntent: PendingIntent = PendingIntent.getActivity(
            context,
            notificationId, // Use notificationId as request code for uniqueness
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher) // Use the default app icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true) // Dismiss notification when tapped
            .setContentIntent(contentPendingIntent) // Set the tap action

        with(NotificationManagerCompat.from(context)) {
            // notificationId is a unique int for each notification that you must define
            try {
                 notify(notificationId, builder.build())
                 println("Notification displayed with ID: $notificationId")
            } catch (e: SecurityException) {
                // This can happen if POST_NOTIFICATIONS permission is revoked after scheduling
                 println("SecurityException: Could not display notification $notificationId. Check POST_NOTIFICATIONS permission.")
                 // Optionally, you could try to request permission again here, but it's complex from a receiver
            }

        }
    }

    private fun createNotificationChannel(context: Context) {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Habit Reminders"
            val descriptionText = "Notifications to remind you of your habits"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            // Register the channel with the system
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
             println("Notification channel '$CHANNEL_ID' created or already exists.")
        }
    }
}
