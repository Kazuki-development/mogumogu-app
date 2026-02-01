import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      // iOS settings can be added here
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // CRITICAL FIX: Create notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'expiry_channel', // id (must match the one used in scheduleExpiryNotification)
      'Expiration Alerts', // name
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

  Future<void> scheduleExpiryNotification(FoodItem item) async {
    for (final daysBefore in item.notificationSettings) {
      final scheduledDate = item.expiryDate.subtract(Duration(days: daysBefore));
      var scheduledTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        11, // 11 AM default
        0,
      );

      // If scheduled time is in the past, don't schedule
      // However, if it's TODAY and hasn't passed 11 AM yet? Or if it's TODAY and passed?
      // For improved reliability:
      // If the scheduled time is in the past, checking if it is still "Today" might be relevant for some use cases,
      // but generally we skip past events. 
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

      final notificationId = (item.id ?? 0) * 1000 + daysBefore;

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
          // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // REMOVED due to build error (param not found)
          // matchDateTimeComponents: DateTimeComponents.time, 
        );
      } catch (e) {
        // e.g. Exact alarms permission not granted
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  Future<void> rescheduleAllNotifications(List<FoodItem> items) async {
    // Cancel all existing to be safe and avoid duplicates/stale data
    await flutterLocalNotificationsPlugin.cancelAll();
    
    for (final item in items) {
      await scheduleExpiryNotification(item);
    }
  }
  
  Future<void> cancelConfigurations(int itemId, List<int> settings) async {
    for (final daysBefore in settings) {
      final notificationId = itemId * 1000 + daysBefore;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> cancelNotification(int id) async {
     // Deprecated or basic cancellation. ideally use cancelConfigurations
     // This is kept for backward compatibility if needed, 
     // but since we changed logic, we should use cancelConfigurations.
     // However, without knowing settings, we can't efficiently cancel specific ones 
     // unless we cancel all reasonable range or cancel by group (if supported).
     // Since Android API allows cancel by ID, we need IDs.
     // We will update ViewModel to pass settings.
     await flutterLocalNotificationsPlugin.cancel(id);
  }
}
