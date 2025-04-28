import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request notification permissions for Android (API 33+)
    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }

    // Initialize local notifications
    await _initLocalNotifications();

    // Get and print the FCM token (useful for testing)
    String? token = await _messaging.getToken();
    debugPrint("FCM Token: $token"); 

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Received a foreground message: ${message.notification?.title}");
      _showNotification(message);
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked: ${message.notification?.title}");
      // You can navigate to a specific screen if needed
    });
  }

  /// Request notification permission for Android (API 33+)
  Future<void> _requestAndroidPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("User granted permission for notifications.");
    } else {
      debugPrint("User denied or has not accepted notification permissions.");
    }
  }

  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);
  }

  /// Show a local notification when a Firebase message arrives
  Future<void> _showNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'muslim_kids_channel', // Make sure this ID matches your channel ID
      'Muslim Kids Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0, // Notification ID
      message.notification!.title,
      message.notification!.body,
      details,
    );
  }
}
