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
import 'package:muslim_kids/quiz_debug_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
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
  await FirebaseNotificationService().init();
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {'/quiz_debug': (context) => const QuizDebugScreen()},
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
                    _ensureUserDataConsistency(user, userData);

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
  ) async {
    try {
      // Always use Firebase Auth UID as document ID
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create a new document with the user's UID as the document ID
        await docRef.set({
          ...userData,
          'email': user.email ?? userData['email'] ?? '',
          'uid': user.uid, // Store UID in the document for reference
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        debugPrint("Created user document with UID: ${user.uid}");
      } else {
        // Update existing document to ensure it has the UID field
        if (docSnapshot.data()?['uid'] != user.uid) {
          await docRef.update({
            'uid': user.uid,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          debugPrint("Updated user document with UID: ${user.uid}");
        }
      }
    } catch (e) {
      debugPrint("Error ensuring user data consistency: $e");
    }
  }
}
