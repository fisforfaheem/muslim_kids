import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? _currentFcmToken; // Static variable to hold the token

  // Getter for the current FCM token
  static String? get currentFcmToken => _currentFcmToken;

  Future<String?> init() async {
    // Return type changed to Future<String?>
    // Request notification permissions for Android (API 33+)
    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }

    // Initialize local notifications
    await _initLocalNotifications();

    // Get and print the FCM token (useful for testing)
    _currentFcmToken = await _messaging.getToken();
    debugPrint("🔔 FCM Token: $_currentFcmToken");

    // Update the token in Firestore for the current user
    await _updateTokenInFirestore(_currentFcmToken);

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM Token Refreshed: $newToken");
      _currentFcmToken = newToken;
      _updateTokenInFirestore(newToken);
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        "📱 Received foreground message: ${message.notification?.title}",
      );
      LocalNotificationService.handleForegroundMessage(message);
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("👆 Notification tapped: ${message.notification?.title}");
      _handleNotificationTap(message);
    });

    // Handle initial message (when app is opened from terminated state via notification)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        "🚀 App opened from notification: ${initialMessage.notification?.title}",
      );
      _handleNotificationTap(initialMessage);
    }

    return _currentFcmToken; // Return the token
  }

  // Update FCM token in Firestore for the current user
  Future<void> _updateTokenInFirestore(String? token) async {
    if (token == null) return;

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
        debugPrint(
          "✅ FCM token updated in Firestore for user: ${currentUser.uid}",
        );
      } else {
        debugPrint("⚠️ No authenticated user to update FCM token");
      }
    } catch (e) {
      debugPrint("❌ Error updating FCM token in Firestore: $e");
    }
  }

  // Handle notification tap actions
  void _handleNotificationTap(RemoteMessage message) {
    // Extract notification data
    String? type = message.data['type'];
    String? classId = message.data['classId'];

    debugPrint("📊 Notification tap data: Type=$type, ClassID=$classId");

    // Handle different notification types
    switch (type) {
      case 'new_class':
      case 'class_reminder':
        if (classId != null) {
          // Navigate to class details or live classes page
          debugPrint("🏫 Should navigate to class: $classId");
          // You can add navigation logic here
        }
        break;
      case 'test':
        debugPrint("🧪 Test notification tapped");
        break;
      default:
        debugPrint("❓ Unknown notification type: $type");
    }
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

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

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

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      0, // Notification ID
      message.notification!.title,
      message.notification!.body,
      details,
    );
  }
}
