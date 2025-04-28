import 'package:flutter/material.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:muslim_kids/welcome_page1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muslim_kids/home_page.dart';
import 'firebase_notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseNotificationService().init();
  await LocalNotificationService.initialize();
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
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
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.done) {
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    Map<String, dynamic> userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    String userType = userData['userType'] ?? 'Kid';
                    String email = userData['email'] ?? user.email ?? '';
                    return HomePage(userType: userType, email: email);
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
}
