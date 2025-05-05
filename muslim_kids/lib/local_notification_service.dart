import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

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

    // Request permissions (for iOS)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // For Android 13+, request exact alarm permission
    await _requestExactAlarmPermissionIfNeeded();

    // Request other Android permissions if needed
    await _requestAndroidPermissionsIfNeeded();

    _initialized = true;
    debugPrint('$TAG Notification service initialized successfully');

    // Test notification to verify permissions and setup
    await showTestNotification();
  }

  // Check if notification permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      final bool? permissionsGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      return permissionsGranted ?? false;
    } catch (e) {
      debugPrint('$TAG Error checking notification permissions: $e');
      return false;
    }
  }

  // Show a test notification to verify permissions and setup
  static Future<void> showTestNotification() async {
    try {
      await showNotification(
          id: 0,
          title: 'Notification Test',
          body: 'This is a test notification to verify setup');
      debugPrint('$TAG Test notification sent successfully');
    } catch (e) {
      debugPrint('$TAG Error sending test notification: $e');
    }
  }

  // Request exact alarm permission for Android 13+
  static Future<void> _requestExactAlarmPermissionIfNeeded() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? hasExactAlarmPermission =
            await androidImplementation.canScheduleExactNotifications();

        if (hasExactAlarmPermission == false) {
          await androidImplementation.requestExactAlarmsPermission();
          debugPrint('$TAG Requested exact alarm permission');
        }
      }
    } catch (e) {
      debugPrint('$TAG Error requesting exact alarm permission: $e');
    }
  }

  // Request additional Android permissions if needed
  static Future<void> _requestAndroidPermissionsIfNeeded() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request notification permissions for Android 13+
        await androidImplementation.requestNotificationsPermission();
        debugPrint('$TAG Requested Android notification permissions');
      }
    } catch (e) {
      debugPrint('$TAG Error requesting Android permissions: $e');
    }
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint('$TAG Cancelled notification with ID: $id');
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('$TAG Cancelled all notifications');
  }

  // Show an instant notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Ensure service is initialized
    if (!_initialized) await initialize();

    // Create Android notification details with or without sound
    AndroidNotificationDetails androidDetails;
    try {
      androidDetails = const AndroidNotificationDetails(
        'muslim_kids_channel',
        'Muslim Kids Notifications',
        channelDescription: 'Notifications for Muslim Kids app',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableLights: true,
        color: Color.fromARGB(255, 255, 154, 162),
        ledColor: Color.fromARGB(255, 255, 154, 162),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
    } catch (e) {
      // Fallback to default sound if adhan not found
      debugPrint('$TAG Using default sound: $e');
      androidDetails = const AndroidNotificationDetails(
        'muslim_kids_channel',
        'Muslim Kids Notifications',
        channelDescription: 'Notifications for Muslim Kids app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableLights: true,
        color: Color.fromARGB(255, 255, 154, 162),
        ledColor: Color.fromARGB(255, 255, 154, 162),
        ledOnMs: 1000,
        ledOffMs: 500,
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
    debugPrint("$TAG 🟢 Notification displayed successfully! ID: $id");
  }

  // Schedule a notification for a future time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Ensure service is initialized
    if (!_initialized) await initialize();

    // Create Android notification details with or without sound
    AndroidNotificationDetails androidDetails;
    try {
      androidDetails = const AndroidNotificationDetails(
        'muslim_kids_channel',
        'Muslim Kids Notifications',
        channelDescription: 'Notifications for Muslim Kids app',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableLights: true,
        color: Color.fromARGB(255, 255, 154, 162),
        ledColor: Color.fromARGB(255, 255, 154, 162),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true,
      );
    } catch (e) {
      // Fallback to default sound if adhan not found
      debugPrint('$TAG Using default sound: $e');
      androidDetails = const AndroidNotificationDetails(
        'muslim_kids_channel',
        'Muslim Kids Notifications',
        channelDescription: 'Notifications for Muslim Kids app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableLights: true,
        color: Color.fromARGB(255, 255, 154, 162),
        ledColor: Color.fromARGB(255, 255, 154, 162),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true,
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

    try {
      // Log the timezone information
      String timezoneName = tz.local.name;
      debugPrint("$TAG Using timezone: $timezoneName");

      // Convert DateTime to TZDateTime
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Log the scheduled time
      debugPrint(
          "$TAG Original time: ${scheduledTime.toString()}, TZ time: ${scheduledDate.toString()}");

      // Cancel previous notification with same ID
      await cancelNotification(id);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
          "$TAG 🟢 Notification scheduled for: ${scheduledTime.toString()}, ID: $id");
    } catch (e) {
      debugPrint("$TAG 🔴 Error scheduling notification: $e");
      // If scheduling fails, try to show it immediately as a fallback
      await showNotification(
          id: id, title: title, body: body, payload: payload);
    }
  }

  // Daily scheduled notification
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed for today, schedule for tomorrow
    final DateTime finalTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: finalTime,
      payload: payload,
    );
  }
}
