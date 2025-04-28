import 'package:flutter/material.dart';
import 'package:muslim_kids/local_notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143), // Set background color to yellow
      appBar: AppBar(
        backgroundColor: Colors.pink[200],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[300],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            await LocalNotificationService.showNotification(
              id: 0,
              title: "Test Notification",
              body: "This is a test notification!",
            );
          },
          child: const Text(
            'Show Test Notification',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
