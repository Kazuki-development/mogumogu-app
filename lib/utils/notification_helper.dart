
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
    // Use the default local location or set it to a specific one if needed
    // tz.setLocalLocation(tz.getLocation('Asia/Tokyo')); 

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
  }

  Future<void> scheduleExpiryNotification(FoodItem item) async {
    for (final daysBefore in item.notificationSettings) {
      final scheduledDate = item.expiryDate.subtract(Duration(days: daysBefore));
      var scheduledTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        11, // 11 AM
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

      // Unique ID for each notification setting: itemId * 1000 + daysBefore
      // Max items assumption: 2M. 2M * 1000 = 2B (within int32 range)
      // Note: daysBefore should ideally be small < 1000.
      final notificationId = (item.id ?? 0) * 1000 + daysBefore;

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
