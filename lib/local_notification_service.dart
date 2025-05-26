import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String TAG = "LocalNotificationService";
  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('$TAG Already initialized');
      return;
    }

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Get device timezone
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('$TAG Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('$TAG Error setting timezone: $e');
      // Use UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization Settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Complete Initialization Settings
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings and handle notification taps
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('$TAG Notification tapped: ${details.payload}');
        // Handle notification tap
      },
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Request permissions
    await _requestPermissions();

    _initialized = true;
    debugPrint('$TAG ✅ Notification service initialized successfully');
  }

  // Create notification channels for different types of notifications
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      // Default channel
      AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'Default notifications for the app',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
      // Class notifications
      AndroidNotificationChannel(
        'class_notifications',
        'Class Notifications',
        description: 'Notifications about new classes and updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // Reminder notifications
      AndroidNotificationChannel(
        'reminder_notifications',
        'Class Reminders',
        description: 'Reminders for upcoming classes',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // Prayer notifications
      AndroidNotificationChannel(
        'prayer_notifications',
        'Prayer Reminders',
        description: 'Prayer time reminders',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      ),
      // Test notifications
      AndroidNotificationChannel(
        'test_notifications',
        'Test Notifications',
        description: 'Test notifications for debugging',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      debugPrint("$TAG Created notification channel: ${channel.id}");
    }
  }

  // Request permissions for notifications
  static Future<void> _requestPermissions() async {
    try {
      // Request permissions for iOS
      if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      // Request permissions for Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          // Request notification permissions for Android 13+
          await androidImplementation.requestNotificationsPermission();

          // Request exact alarm permission
          final bool? hasExactAlarmPermission =
              await androidImplementation.canScheduleExactNotifications();
          if (hasExactAlarmPermission == false) {
            await androidImplementation.requestExactAlarmsPermission();
          }
        }
      }

      debugPrint('$TAG ✅ Notification permissions requested');
    } catch (e) {
      debugPrint('$TAG ❌ Error requesting permissions: $e');
    }
  }

  // Check if notification permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          final bool? permissionsGranted =
              await androidImplementation.areNotificationsEnabled();
          return permissionsGranted ?? false;
        }
      }

      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        if (iosImplementation != null) {
          final NotificationsEnabledOptions? permissionsResult =
              await iosImplementation.checkPermissions();
          return permissionsResult?.isEnabled ?? false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('$TAG ❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Get channel name by ID
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'class_notifications':
        return 'Class Notifications';
      case 'reminder_notifications':
        return 'Class Reminders';
      case 'prayer_notifications':
        return 'Prayer Reminders';
      case 'test_notifications':
        return 'Test Notifications';
      default:
        return 'Default Notifications';
    }
  }

  // Get channel description by ID
  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'class_notifications':
        return 'Notifications about new classes and updates';
      case 'reminder_notifications':
        return 'Reminders for upcoming classes';
      case 'prayer_notifications':
        return 'Prayer time reminders';
      case 'test_notifications':
        return 'Test notifications for debugging';
      default:
        return 'Default notifications for the app';
    }
  }

  // Show an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
  }) async {
    if (!_initialized) await initialize();

    // Create Android notification details with the specified channel
    AndroidNotificationDetails androidDetails;

    if (channelId == 'prayer_notifications') {
      // Use adhan sound for prayer notifications
      try {
        androidDetails = AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adhan'),
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 255, 154, 162),
        );
      } catch (e) {
        // Fallback to default sound if adhan not found
        androidDetails = AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 255, 154, 162),
        );
      }
    } else {
      // Use default sound for other notifications
      androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: Color.fromARGB(255, 76, 175, 80), // Green for FCM notifications
      );
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
    debugPrint("$TAG 📱 Notification shown: $title");
  }

  // Schedule a notification for a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'reminder_notifications',
  }) async {
    if (!_initialized) await initialize();

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint(
        "$TAG ⚠️ Cannot schedule notification in the past: $scheduledTime",
      );
      return;
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color.fromARGB(255, 255, 152, 0), // Orange for reminders
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
        "$TAG ⏰ Scheduled notification: $title at $scheduledTime (ID: $id)",
      );
    } catch (e) {
      debugPrint("$TAG ❌ Error scheduling notification: $e");
    }
  }

  // Handle FCM notification received in foreground
  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      "$TAG 🔔 FCM Foreground Message: ${message.notification?.title}",
    );

    if (message.notification != null) {
      await showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
        channelId: _getChannelIdFromMessage(message),
      );
    }
  }

  // Handle FCM notification received in background
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint(
      "$TAG 🔔 FCM Background Message: ${message.notification?.title}",
    );

    if (message.data.isNotEmpty) {
      debugPrint("$TAG Background message data: ${message.data}");

      switch (message.data['type']) {
        case 'new_class':
          debugPrint("$TAG New class notification received");
          break;
        case 'class_reminder':
          debugPrint("$TAG Class reminder notification received");
          break;
        case 'test':
          debugPrint("$TAG Test notification received");
          break;
        default:
          debugPrint("$TAG Unknown notification type: ${message.data['type']}");
      }
    }
  }

  // Get appropriate channel ID based on message type
  static String _getChannelIdFromMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      switch (message.data['type']) {
        case 'new_class':
          return 'class_notifications';
        case 'class_reminder':
          return 'reminder_notifications';
        case 'prayer_reminder':
          return 'prayer_notifications';
        case 'test':
          return 'test_notifications';
        default:
          return 'default_channel';
      }
    }
    return 'default_channel';
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint("$TAG ❌ Cancelled notification with ID: $id");
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("$TAG ❌ Cancelled all notifications");
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Show class-specific notification
  static Future<void> showClassNotification({
    required String classId,
    required String title,
    required String body,
    required String topic,
    required String teacher,
    required String date,
    required String time,
  }) async {
    await showNotification(
      id: classId.hashCode,
      title: title,
      body: body,
      payload: 'class:$classId',
      channelId: 'class_notifications',
    );
  }

  // Show reminder notification
  static Future<void> showReminderNotification({
    required String classId,
    required String topic,
    required String time,
    required int reminderMinutes,
  }) async {
    await showNotification(
      id: ("${classId}_reminder").hashCode,
      title: "⏰ Class Starting Soon!",
      body: "Class: $topic, Time: $time ($reminderMinutes mins before)",
      payload: 'reminder:$classId',
      channelId: 'reminder_notifications',
    );
  }
}
