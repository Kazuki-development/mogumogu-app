import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationHelper._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Create notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'expiry_channel',
      'Expiration Alerts',
      description: 'Notifications for expiring food',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request notification permissions (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Check and request exact alarm permission (Android 12+).
  /// Returns true if permission is granted, false otherwise.
  Future<bool> ensureExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    }

    // Request the permission - this will open OS settings for exact alarm
    final result = await Permission.scheduleExactAlarm.request();
    if (result.isGranted) {
      return true;
    }

    debugPrint('SCHEDULE_EXACT_ALARM permission not granted. Status: $result');
    return false;
  }

  /// Generate a safe notification ID that stays within int32 range.
  /// Uses a combination of item id and daysBefore to create a unique ID.
  int _generateNotificationId(int? itemId, int daysBefore) {
    // Use a safe hash: itemId is typically a small DB auto-increment integer
    // Limit to positive int32 range: 0 to 2,147,483,647
    final base = (itemId ?? 0).abs() % 2000000; // Keep base under 2M
    return base * 1000 + daysBefore; // Max: ~2,000,999,999 (within int32)
  }

  Future<void> scheduleExpiryNotification(FoodItem item) async {
    // Check exact alarm permission before scheduling
    final hasPermission = await ensureExactAlarmPermission();
    if (!hasPermission) {
      debugPrint('Cannot schedule notification: SCHEDULE_EXACT_ALARM permission denied');
      return;
    }

    for (final daysBefore in item.notificationSettings) {
      final scheduledDate = item.expiryDate.subtract(Duration(days: daysBefore));
      var scheduledTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        11, // 11 AM default
        0,
      );

      // If scheduled time is in the past, skip
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('Skipping notification for ${item.name} ($daysBefore days before): scheduled time is in the past');
        continue;
      }

      String title = 'もぐもぐ通知';
      String body = '';
      if (daysBefore == 0) {
        body = '${item.name} の賞味期限は今日です！';
      } else if (daysBefore == 1) {
        body = '${item.name} の賞味期限は明日です！';
      } else {
        body = '${item.name} の賞味期限まであと $daysBefore 日です！';
      }

      final notificationId = _generateNotificationId(item.id, daysBefore);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              'Expiration Alerts',
              channelDescription: 'Notifications for expiring food',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('Scheduled notification for ${item.name}: $daysBefore days before expiry (id=$notificationId, time=$scheduledTime)');
      } catch (e) {
        debugPrint('Error scheduling notification for ${item.name}: $e');
      }
    }
  }

  Future<void> rescheduleAllNotifications(List<FoodItem> items) async {
    // Check permission once before rescheduling all
    final hasPermission = await ensureExactAlarmPermission();
    if (!hasPermission) {
      debugPrint('Cannot reschedule notifications: SCHEDULE_EXACT_ALARM permission denied');
      return;
    }

    // Cancel all existing to avoid duplicates/stale data
    await flutterLocalNotificationsPlugin.cancelAll();

    int scheduledCount = 0;
    for (final item in items) {
      for (final daysBefore in item.notificationSettings) {
        final scheduledDate = item.expiryDate.subtract(Duration(days: daysBefore));
        var scheduledTime = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          11,
          0,
        );

        if (scheduledTime.isBefore(DateTime.now())) {
          continue;
        }

        String title = 'もぐもぐ通知';
        String body = '';
        if (daysBefore == 0) {
          body = '${item.name} の賞味期限は今日です！';
        } else if (daysBefore == 1) {
          body = '${item.name} の賞味期限は明日です！';
        } else {
          body = '${item.name} の賞味期限まであと $daysBefore 日です！';
        }

        final notificationId = _generateNotificationId(item.id, daysBefore);

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            tz.TZDateTime.from(scheduledTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'expiry_channel',
                'Expiration Alerts',
                channelDescription: 'Notifications for expiring food',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledCount++;
        } catch (e) {
          debugPrint('Error scheduling notification for ${item.name}: $e');
        }
      }
    }
    debugPrint('Rescheduled $scheduledCount notifications for ${items.length} items');
  }

  Future<void> cancelConfigurations(int itemId, List<int> settings) async {
    for (final daysBefore in settings) {
      final notificationId = _generateNotificationId(itemId, daysBefore);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
