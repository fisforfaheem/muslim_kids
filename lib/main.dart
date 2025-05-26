import 'package:flutter/material.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:muslim_kids/welcome_page1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/home_page.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';
import 'package:muslim_kids/services/boot_notification_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_notification_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:muslim_kids/add_multiple_quizzes.dart';
import 'package:muslim_kids/quiz_debug_screen.dart';

@pragma('vm:entry-point') // Ensures it can be called from isolate
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  await LocalNotificationService.initialize(); // Ensure local notifications are ready

  debugPrint("🔔 Handling FCM background message: ${message.messageId}");
  debugPrint("📊 Message data: ${message.data}");

  // Use the LocalNotificationService to handle background messages
  await LocalNotificationService.handleBackgroundMessage(message);

  // If there's a notification payload, show it
  String? title = message.notification?.title;
  String? body = message.notification?.body;

  if (title != null && body != null) {
    // Use a unique ID for the notification
    int notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    // Determine channel based on message type
    String channelId = 'default_channel';
    if (message.data.isNotEmpty) {
      switch (message.data['type']) {
        case 'new_class':
          channelId = 'class_notifications';
          break;
        case 'class_reminder':
          channelId = 'reminder_notifications';
          break;
        case 'prayer_reminder':
          channelId = 'prayer_notifications';
          break;
        case 'test':
          channelId = 'test_notifications';
          break;
        default:
          channelId = 'default_channel';
      }
    }

    await LocalNotificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: message.data.toString(),
      channelId: channelId,
    );

    debugPrint("✅ Background notification shown: $title");
  } else {
    debugPrint("⚠️ Background message did not contain notification payload");
  }
}

// Helper method to safely request a permission and handle errors
Future<PermissionStatus> _safeRequestPermission(
  Permission permission,
  String permissionName,
) async {
  try {
    final status = await permission.request();
    debugPrint("$permissionName permission status: $status");
    if (status != PermissionStatus.granted) {
      debugPrint("⚠️ $permissionName permission not granted: $status");
    }
    return status;
  } catch (e) {
    debugPrint("⚠️ Error requesting $permissionName permission: $e");
    return PermissionStatus.denied;
  }
}

Future<void> _requestPermissions() async {
  // Request notification permission
  await _safeRequestPermission(Permission.notification, "Notification");

  // Request exact alarm permission (for background alarms)
  await _safeRequestPermission(Permission.scheduleExactAlarm, "Exact alarm");

  // Request ignore battery optimization permission
  await _safeRequestPermission(
    Permission.ignoreBatteryOptimizations,
    "Battery optimization",
  );
}

Future<void> _setupTimezone() async {
  tz_data.initializeTimeZones();
  try {
    final String timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
    debugPrint("🕒 Timezone set to: $timeZone");
  } catch (e) {
    debugPrint("⚠️ Error setting timezone: $e");
    tz.setLocalLocation(tz.getLocation('UTC')); // Fallback to UTC
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup timezone first for proper notification scheduling
  await _setupTimezone();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Request permissions early
  await _requestPermissions();

  // Set up background message handler first to avoid duplicate isolates
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification services
  final fcmToken = await FirebaseNotificationService().init();
  await LocalNotificationService.initialize();

  // Initialize boot notification handler for rescheduling after device restart
  try {
    await BootNotificationHandler.initialize();
    debugPrint("✅ Boot notification handler initialized successfully");
  } catch (e) {
    debugPrint("⚠️ Error initializing boot notification handler: $e");
    // Continue anyway, as this is not critical for app startup
  }

  // Initialize prayer alarm service - always schedule notifications
  // even if user is not logged in (will use default prayer times)
  final prayerAlarmService = PrayerAlarmService();
  await prayerAlarmService.scheduleAllPrayerTimeNotifications();

  runApp(MyApp(fcmToken: fcmToken));
}

class MyApp extends StatelessWidget {
  final String? fcmToken;
  const MyApp({super.key, this.fcmToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(fcmToken: fcmToken),
      routes: {},
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final String? fcmToken;
  const AuthWrapper({super.key, this.fcmToken});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            // User is signed in, check Firestore for user type
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.done) {
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    Map<String, dynamic> userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;

                    // Store user data in Firestore with the correct ID
                    _ensureUserDataConsistency(user, userData, fcmToken);

                    String userType = userData['userType'] ?? 'Kid';
                    String email = userData['email'] ?? user.email ?? '';
                    String name = userData['name'] ?? '';
                    String avatar = userData['avatar'] ?? 'assets/avatar2.jpg';
                    return HomePage(
                      userType: userType,
                      email: email,
                      name: name,
                      avatar: avatar,
                    );
                  }
                }
                // If we're waiting for Firestore or user data doesn't exist yet
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
        }
        // Show welcome page if user is not signed in or connection is not active
        return const WelcomePage();
      },
    );
  }

  // Ensure user data consistency between Auth UID and Firestore Document ID
  Future<void> _ensureUserDataConsistency(
    User user,
    Map<String, dynamic> userData,
    String? fcmToken,
  ) async {
    try {
      // Always use Firebase Auth UID as document ID
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await docRef.get();

      Map<String, dynamic> dataToSetOrUpdate = {
        ...userData,
        'email': user.email ?? userData['email'] ?? '',
        'uid': user.uid, // Store UID in the document for reference
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add FCM token if available and different from existing (or if not exists)
      if (fcmToken != null && fcmToken.isNotEmpty) {
        if (!docSnapshot.exists ||
            docSnapshot.data()?['fcmToken'] != fcmToken) {
          dataToSetOrUpdate['fcmToken'] = fcmToken;
        }
      }

      if (!docSnapshot.exists) {
        // Create a new document with the user's UID as the document ID
        await docRef.set(dataToSetOrUpdate);
        debugPrint(
          "Created user document with UID: ${user.uid} and FCM Token: $fcmToken",
        );
      } else {
        // Update existing document to ensure it has the UID field and potentially new FCM token
        Map<String, dynamic> updates = {};
        if (docSnapshot.data()?['uid'] != user.uid) {
          updates['uid'] = user.uid;
        }
        if (fcmToken != null &&
            fcmToken.isNotEmpty &&
            docSnapshot.data()?['fcmToken'] != fcmToken) {
          updates['fcmToken'] = fcmToken;
        }
        if (updates.isNotEmpty) {
          updates['lastUpdated'] = FieldValue.serverTimestamp();
          await docRef.update(updates);
          debugPrint(
            "Updated user document for UID: ${user.uid}. Changes: $updates",
          );
        }
      }
    } catch (e) {
      debugPrint("Error ensuring user data consistency: $e");
    }
  }
}
