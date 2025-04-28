import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  static Future<void> initialize() async {
    // Android Initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);

  }

  // Show an instant notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'class_notifications',
      'Class Notifications',
      channelDescription: 'Notifications for scheduled classes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
    debugPrint("🟢 Notification scheduled successfully!");
  }      
}
