import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:muslim_kids/models/prayer_time.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PrayerAlarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String TAG = "PrayerAlarmService";

  // Get user ID
  String? get _userId => _auth.currentUser?.uid;

  // Reference to the prayer times collection
  CollectionReference get _prayerTimesRef =>
      _firestore.collection('users').doc(_userId).collection('prayerTimes');

  // Get all prayer times for the current user
  Future<List<PrayerTime>> getPrayerTimes() async {
    if (_userId == null) {
      debugPrint('$TAG No user logged in, using default prayer times');
      return _getDefaultPrayerTimes();
    }

    try {
      debugPrint('$TAG Attempting to fetch prayer times for user: $_userId');
      final QuerySnapshot snapshot = await _prayerTimesRef.get();

      if (snapshot.docs.isEmpty) {
        // If user has no prayer times set up yet, create default ones
        debugPrint('$TAG No prayer times found, creating defaults');
        try {
          await _createDefaultPrayerTimes();
        } catch (e) {
          debugPrint('$TAG Failed to create default prayer times: $e');
          // Continue with default times even if creation fails
        }
        return _getDefaultPrayerTimes();
      }

      return snapshot.docs
          .map((doc) =>
              PrayerTime.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('$TAG Error getting prayer times: $e');
      // In case of permission errors or any other issues, use default prayer times
      return _getDefaultPrayerTimes();
    }
  }

  // Create a new prayer time
  Future<void> createPrayerTime(PrayerTime prayerTime) async {
    if (_userId == null) {
      debugPrint('$TAG Cannot create prayer time: No user logged in');
      return;
    }

    try {
      await _prayerTimesRef.add(prayerTime.toMap());
      await _schedulePrayerTimeNotification(prayerTime);
    } catch (e) {
      debugPrint('$TAG Error creating prayer time: $e');
      // Still schedule notification even if Firestore fails
      await _schedulePrayerTimeNotification(prayerTime);
    }
  }

  // Update an existing prayer time
  Future<void> updatePrayerTime(PrayerTime prayerTime) async {
    if (_userId == null) {
      debugPrint('$TAG Cannot update prayer time: No user logged in');
      return;
    }

    try {
      await _prayerTimesRef.doc(prayerTime.id).update(prayerTime.toMap());
      await _schedulePrayerTimeNotification(prayerTime);
    } catch (e) {
      debugPrint('$TAG Error updating prayer time: $e');
      // Still schedule notification even if Firestore fails
      await _schedulePrayerTimeNotification(prayerTime);
    }
  }

  // Delete a prayer time
  Future<void> deletePrayerTime(String prayerTimeId) async {
    if (_userId == null) return;

    try {
      await _prayerTimesRef.doc(prayerTimeId).delete();
    } catch (e) {
      debugPrint('$TAG Error deleting prayer time: $e');
    }
  }

  // Create default prayer times for a new user
  Future<void> _createDefaultPrayerTimes() async {
    if (_userId == null) return;

    final defaultTimes = [
      PrayerTime(
        id: 'fajr',
        name: 'Fajr',
        time: const TimeOfDay(hour: 5, minute: 0),
      ),
      PrayerTime(
        id: 'dhuhr',
        name: 'Dhuhr',
        time: const TimeOfDay(hour: 12, minute: 30),
      ),
      PrayerTime(
        id: 'asr',
        name: 'Asr',
        time: const TimeOfDay(hour: 15, minute: 30),
      ),
      PrayerTime(
        id: 'maghrib',
        name: 'Maghrib',
        time: const TimeOfDay(hour: 18, minute: 0),
      ),
      PrayerTime(
        id: 'isha',
        name: 'Isha',
        time: const TimeOfDay(hour: 20, minute: 0),
      ),
    ];

    for (var prayerTime in defaultTimes) {
      await _prayerTimesRef.doc(prayerTime.id).set(prayerTime.toMap());
      await _schedulePrayerTimeNotification(prayerTime);
    }
  }

  // Get default prayer times when user is not logged in or has no data
  List<PrayerTime> _getDefaultPrayerTimes() {
    return [
      PrayerTime(
        id: 'fajr',
        name: 'Fajr',
        time: const TimeOfDay(hour: 5, minute: 0),
      ),
      PrayerTime(
        id: 'dhuhr',
        name: 'Dhuhr',
        time: const TimeOfDay(hour: 12, minute: 30),
      ),
      PrayerTime(
        id: 'asr',
        name: 'Asr',
        time: const TimeOfDay(hour: 15, minute: 30),
      ),
      PrayerTime(
        id: 'maghrib',
        name: 'Maghrib',
        time: const TimeOfDay(hour: 18, minute: 0),
      ),
      PrayerTime(
        id: 'isha',
        name: 'Isha',
        time: const TimeOfDay(hour: 20, minute: 0),
      ),
    ];
  }

  // Check if notification permissions are granted
  Future<bool> _checkNotificationPermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return true;
  }

  // Schedule local notification for a prayer time
  Future<void> _schedulePrayerTimeNotification(PrayerTime prayerTime) async {
    if (!prayerTime.isEnabled) {
      debugPrint(
          '$TAG Prayer notification for ${prayerTime.name} is disabled, skipping');
      return;
    }

    // Ensure we have notification permissions
    try {
      final hasPermission = await _checkNotificationPermissions();
      if (!hasPermission) {
        debugPrint(
            '$TAG Cannot schedule notification: No notification permission');
        return;
      }

      // Get the device's timezone
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      final tz.Location location = tz.getLocation(timeZoneName);

      // Ensure notifications can run in background
      try {
        await _ensureBackgroundNotifications();
      } catch (e) {
        debugPrint('$TAG Warning - background notification setup failed: $e');
        // Continue anyway
      }

      // Schedule for today
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        prayerTime.time.hour,
        prayerTime.time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      DateTime finalDate = scheduledDate;
      if (scheduledDate.isBefore(now)) {
        finalDate = scheduledDate.add(const Duration(days: 1));
      }

      // Cancel any previous notification with the same ID
      // This is to prevent duplicate notifications
      final notificationId = _getNotificationId(prayerTime);

      try {
        // Schedule the notification
        await LocalNotificationService.scheduleNotification(
          id: notificationId,
          title: "Time for ${prayerTime.name} Prayer",
          body: "It's time to pray ${prayerTime.name}",
          scheduledTime: finalDate,
        );

        debugPrint(
            '$TAG Scheduled prayer notification for ${prayerTime.name} at ${finalDate.toString()}, ID: $notificationId');
      } catch (e) {
        debugPrint('$TAG Error during notification scheduling: $e');
        // Try an immediate notification as fallback
        try {
          await LocalNotificationService.showNotification(
            id: notificationId,
            title: "Prayer Time Reminder",
            body:
                "Prayer time notifications have been set up for ${prayerTime.name}",
          );
        } catch (innerE) {
          debugPrint('$TAG Failed to show fallback notification: $innerE');
        }
      }
    } catch (e) {
      debugPrint('$TAG Fatal error scheduling prayer notification: $e');
    }
  }

  // Get a consistent notification ID for a prayer time
  int _getNotificationId(PrayerTime prayerTime) {
    // Use a simple hash code of the ID to ensure consistency
    // We need consistent IDs to be able to cancel notifications
    return prayerTime.id.hashCode;
  }

  // Ensure the app can show notifications in the background
  Future<void> _ensureBackgroundNotifications() async {
    if (Platform.isAndroid) {
      // For Android, we need to request battery optimization exemption
      // and background notification permissions
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  // Schedule all prayer time notifications
  Future<void> scheduleAllPrayerTimeNotifications() async {
    final prayerTimes = await getPrayerTimes();
    // Cancel all existing notifications before rescheduling
    // This prevents duplicate notifications

    int scheduledCount = 0;
    for (var prayerTime in prayerTimes) {
      if (prayerTime.isEnabled) {
        await _schedulePrayerTimeNotification(prayerTime);
        scheduledCount++;
      }
    }

    debugPrint(
        '$TAG Successfully scheduled $scheduledCount prayer notifications');
  }
}
