import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:muslim_kids/models/prayer_time.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerAlarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String TAG = "PrayerAlarmService";
  static const String PRAYER_CACHE_KEY = "cached_prayer_times";
  static const String LOCATION_CACHE_KEY = "cached_location";
  Position? _lastKnownLocation;
  String _locationName = "Unknown";
  List<PrayerTime>? _cachedPrayerTimes;
  DateTime? _cacheTimestamp;

  // Get user ID
  String? get _userId => _auth.currentUser?.uid;

  // Reference to the prayer times collection
  CollectionReference get _prayerTimesRef =>
      _userId == null
          ? _firestore.collection('public_prayer_times')
          : _firestore
              .collection('user_prayer_times')
              .doc(_userId)
              .collection('times');

  // Get location name
  String get locationName => _locationName;

  // Check location permission
  Future<bool> checkLocationPermission() async {
    debugPrint('$TAG 🔍 Checking location permissions...');
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('$TAG Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        debugPrint('$TAG ❌ Location services are disabled');
        return false;
      }
    } catch (e) {
      debugPrint('$TAG ❌ Error checking location services: $e');
      return false;
    }

    try {
      // Check current permission status
      permission = await Geolocator.checkPermission();
      debugPrint('$TAG Current location permission status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('$TAG Location permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint(
          '$TAG After request, location permission status: $permission',
        );
        if (permission == LocationPermission.denied) {
          debugPrint('$TAG ❌ Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('$TAG ❌ Location permissions are permanently denied');
        return false;
      }

      debugPrint('$TAG ✅ Location permission granted: $permission');
      return true;
    } catch (e) {
      debugPrint('$TAG ❌ Error during permission check: $e');
      return false;
    }
  }

  // Try to load cached location
  Future<Position?> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(LOCATION_CACHE_KEY);

      if (locationJson != null) {
        final locationMap = json.decode(locationJson);
        final cachedLocation = Position(
          longitude: locationMap['longitude'],
          latitude: locationMap['latitude'],
          timestamp: DateTime.parse(locationMap['timestamp']),
          accuracy: locationMap['accuracy'],
          altitude: locationMap['altitude'],
          heading: locationMap['heading'],
          speed: locationMap['speed'],
          speedAccuracy: locationMap['speedAccuracy'],
          floor: locationMap['floor'],
          isMocked: locationMap['isMocked'] ?? false,
          altitudeAccuracy: locationMap['altitudeAccuracy'],
          headingAccuracy: locationMap['headingAccuracy'],
        );

        // Check if cached location is less than 24 hours old
        final now = DateTime.now();
        final difference = now.difference(cachedLocation.timestamp);
        if (difference.inHours < 24) {
          _locationName = "Cached location";
          return cachedLocation;
        }
      }
    } catch (e) {
      debugPrint('$TAG Error loading cached location: $e');
    }
    return null;
  }

  // Cache current location
  Future<void> _cacheLocation(Position location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationMap = {
        'longitude': location.longitude,
        'latitude': location.latitude,
        'timestamp': location.timestamp.toIso8601String(),
        'accuracy': location.accuracy,
        'altitude': location.altitude,
        'heading': location.heading,
        'speed': location.speed,
        'speedAccuracy': location.speedAccuracy,
        'floor': location.floor,
        'isMocked': location.isMocked,
        'altitudeAccuracy': location.altitudeAccuracy,
        'headingAccuracy': location.headingAccuracy,
      };
      await prefs.setString(LOCATION_CACHE_KEY, json.encode(locationMap));
    } catch (e) {
      debugPrint('$TAG Error caching location: $e');
    }
  }

  // Get user's current location with caching
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      debugPrint(
        '$TAG ❌ Location permission denied or location services disabled',
      );
      return await _loadCachedLocation();
    }

    try {
      debugPrint('$TAG 🔍 Attempting to get current location...');

      // First try to get from cache if available
      final cachedLocation = await _loadCachedLocation();

      // Set a shorter timeout for faster response
      _lastKnownLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Lower accuracy for speed
        timeLimit: const Duration(seconds: 5), // Short timeout for better UX
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('$TAG ⚠️ Location fetch timed out, using fallback');
          // Return cached or last known location on timeout
          return cachedLocation ??
              _lastKnownLocation ??
              // If nothing else, return Islamabad coordinates as Position object
              Position(
                longitude: 73.0479,
                latitude: 33.6844,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                floor: null,
                isMocked: false,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
        },
      );

      if (_lastKnownLocation != null) {
        debugPrint(
          '$TAG ✅ Location obtained: ${_lastKnownLocation?.latitude}, ${_lastKnownLocation?.longitude}',
        );

        // Cache the new location
        _cacheLocation(_lastKnownLocation!);

        // Set location name based on coordinates
        _locationName =
            "Lat: ${_lastKnownLocation?.latitude.toStringAsFixed(4)}, "
            "Lng: ${_lastKnownLocation?.longitude.toStringAsFixed(4)}";
      }

      return _lastKnownLocation;
    } catch (e) {
      debugPrint('$TAG ❌ Error getting location: $e');

      // Try cached location first
      final cachedLocation = await _loadCachedLocation();
      if (cachedLocation != null) {
        _lastKnownLocation = cachedLocation;
        debugPrint(
          '$TAG ✅ Using cached location: ${_lastKnownLocation?.latitude}, ${_lastKnownLocation?.longitude}',
        );
        return _lastKnownLocation;
      }

      // Then try getting last known location if no cache
      try {
        debugPrint('$TAG 🔍 Trying to get last known location as fallback...');
        _lastKnownLocation = await Geolocator.getLastKnownPosition();
        if (_lastKnownLocation != null) {
          debugPrint(
            '$TAG ✅ Last known location retrieved: ${_lastKnownLocation?.latitude}, ${_lastKnownLocation?.longitude}',
          );
          _locationName =
              "Last known: Lat: ${_lastKnownLocation?.latitude.toStringAsFixed(4)}, "
              "Lng: ${_lastKnownLocation?.longitude.toStringAsFixed(4)}";
          return _lastKnownLocation;
        }
      } catch (lastKnownError) {
        debugPrint('$TAG ❌ Error getting last known location: $lastKnownError');
      }
      return null;
    }
  }

  // Try to load cached prayer times
  Future<List<PrayerTime>?> _loadCachedPrayerTimes() async {
    if (_cachedPrayerTimes != null && _cacheTimestamp != null) {
      // If cache is from today, use it
      final now = DateTime.now();
      if (now.day == _cacheTimestamp!.day &&
          now.month == _cacheTimestamp!.month &&
          now.year == _cacheTimestamp!.year) {
        debugPrint('$TAG ✅ Using in-memory cached prayer times');
        return _cachedPrayerTimes;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prayerTimesJson = prefs.getString(PRAYER_CACHE_KEY);

      if (prayerTimesJson != null) {
        final prayerTimesMap = json.decode(prayerTimesJson);
        final timestamp = DateTime.parse(prayerTimesMap['timestamp']);

        // Check if cached times are from today
        final now = DateTime.now();
        if (now.day == timestamp.day &&
            now.month == timestamp.month &&
            now.year == timestamp.year) {
          final List<dynamic> prayers = prayerTimesMap['prayers'];
          final cachedPrayers =
              prayers.map((prayer) {
                final timeParts = (prayer['time'] as String).split(':');
                return PrayerTime(
                  id: prayer['id'],
                  name: prayer['name'],
                  time: TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  ),
                  isEnabled: prayer['isEnabled'] ?? true,
                );
              }).toList();

          _cachedPrayerTimes = cachedPrayers;
          _cacheTimestamp = timestamp;
          debugPrint('$TAG ✅ Using disk cached prayer times from today');
          return cachedPrayers;
        }
      }
    } catch (e) {
      debugPrint('$TAG Error loading cached prayer times: $e');
    }
    return null;
  }

  // Cache prayer times
  Future<void> _cachePrayerTimes(List<PrayerTime> prayerTimes) async {
    try {
      _cachedPrayerTimes = prayerTimes;
      _cacheTimestamp = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final prayersJson =
          prayerTimes
              .map(
                (prayer) => {
                  'id': prayer.id,
                  'name': prayer.name,
                  'time':
                      '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}',
                  'isEnabled': prayer.isEnabled,
                },
              )
              .toList();

      final prayerTimesMap = {
        'timestamp': _cacheTimestamp!.toIso8601String(),
        'prayers': prayersJson,
      };

      await prefs.setString(PRAYER_CACHE_KEY, json.encode(prayerTimesMap));
      debugPrint('$TAG ✅ Prayer times cached successfully');
    } catch (e) {
      debugPrint('$TAG Error caching prayer times: $e');
    }
  }

  // Get prayer times based on location
  Future<List<PrayerTime>> getPrayerTimesFromLocation() async {
    debugPrint('$TAG 🔍 Getting prayer times from location...');

    try {
      // First try to load from cache to speed up the initial load
      final cachedTimes = await _loadCachedPrayerTimes();
      if (cachedTimes != null) {
        return cachedTimes;
      }

      // Try to get current location but don't crash if it fails
      Position? location;
      try {
        location = await getCurrentLocation();
      } catch (e) {
        debugPrint(
          '$TAG ⚠️ Error getting location, using default coordinates: $e',
        );
      }

      // If location is null (permission denied or error), use default coordinates
      // These are coordinates for Islamabad, Pakistan
      final double latitude = location?.latitude ?? 33.6844;
      final double longitude = location?.longitude ?? 73.0479;

      _locationName =
          location != null
              ? "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}"
              : "Default location (Islamabad)";

      debugPrint(
        '$TAG 🔄 Calculating prayer times for location: $latitude, $longitude',
      );

      final date = DateComponents.from(DateTime.now());

      // Use Muslim World League calculation method which is widely accepted
      final params = CalculationMethod.muslim_world_league.getParameters();
      // Adjust parameters based on your preference
      params.madhab = Madhab.hanafi;
      params.adjustments.fajr = 2;
      params.adjustments.sunrise = 0;
      params.adjustments.dhuhr = 2;
      params.adjustments.asr = 2;
      params.adjustments.maghrib = 2;
      params.adjustments.isha = 2;

      debugPrint(
        '$TAG Using calculation method: Muslim World League with Hanafi madhab',
      );

      final prayerTimes = PrayerTimes(
        Coordinates(latitude, longitude),
        date,
        params,
      );

      debugPrint('$TAG ✅ Prayer times calculated successfully:');
      debugPrint(
        '$TAG   Fajr: ${prayerTimes.fajr.hour}:${prayerTimes.fajr.minute}',
      );
      debugPrint(
        '$TAG   Dhuhr: ${prayerTimes.dhuhr.hour}:${prayerTimes.dhuhr.minute}',
      );
      debugPrint(
        '$TAG   Asr: ${prayerTimes.asr.hour}:${prayerTimes.asr.minute}',
      );
      debugPrint(
        '$TAG   Maghrib: ${prayerTimes.maghrib.hour}:${prayerTimes.maghrib.minute}',
      );
      debugPrint(
        '$TAG   Isha: ${prayerTimes.isha.hour}:${prayerTimes.isha.minute}',
      );

      // Create prayer times from the adhan package
      final calculatedTimes = [
        PrayerTime(
          id: 'fajr',
          name: 'Fajr',
          time: TimeOfDay.fromDateTime(prayerTimes.fajr),
        ),
        PrayerTime(
          id: 'dhuhr',
          name: 'Dhuhr',
          time: TimeOfDay.fromDateTime(prayerTimes.dhuhr),
        ),
        PrayerTime(
          id: 'asr',
          name: 'Asr',
          time: TimeOfDay.fromDateTime(prayerTimes.asr),
        ),
        PrayerTime(
          id: 'maghrib',
          name: 'Maghrib',
          time: TimeOfDay.fromDateTime(prayerTimes.maghrib),
        ),
        PrayerTime(
          id: 'isha',
          name: 'Isha',
          time: TimeOfDay.fromDateTime(prayerTimes.isha),
        ),
      ];

      // Cache the calculated times
      _cachePrayerTimes(calculatedTimes);

      return calculatedTimes;
    } catch (e) {
      debugPrint('$TAG ❌ Error calculating prayer times: $e');
      return _getDefaultPrayerTimes();
    }
  }

  // Save location-based prayer times to Firestore
  Future<void> saveLocationBasedPrayerTimes(
    List<PrayerTime> prayerTimes,
  ) async {
    if (_userId == null) {
      debugPrint('$TAG ❌ Cannot save prayer times: No user logged in');
      return;
    }

    try {
      debugPrint('$TAG 🔄 Saving location-based prayer times to Firestore...');
      // First, delete existing prayer times
      final batch = _firestore.batch();
      final snapshot = await _prayerTimesRef.get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then, save the new prayer times
      for (var prayerTime in prayerTimes) {
        await _prayerTimesRef.doc(prayerTime.id).set(prayerTime.toMap());
        await _schedulePrayerTimeNotification(prayerTime);
      }

      debugPrint('$TAG ✅ Saved location-based prayer times to Firestore');
    } catch (e) {
      debugPrint('$TAG ❌ Error saving prayer times to Firestore: $e');
      // Schedule notifications even if Firestore fails
      for (var prayerTime in prayerTimes) {
        await _schedulePrayerTimeNotification(prayerTime);
      }
    }
  }

  // Get all prayer times for the current user
  Future<List<PrayerTime>> getPrayerTimes() async {
    debugPrint('$TAG 🔍 Starting prayer times fetch process');

    try {
      // First check for cached prayer times to speed up loading
      final cachedTimes = await _loadCachedPrayerTimes();
      if (cachedTimes != null) {
        // Schedule notifications for cached times
        for (var prayer in cachedTimes) {
          if (prayer.isEnabled) {
            await _schedulePrayerTimeNotification(prayer);
          }
        }
        return cachedTimes;
      }

      // No cache available, try to get location-based prayer times
      debugPrint('$TAG 🔄 Getting location-based prayer times...');
      final locationPrayerTimes = await getPrayerTimesFromLocation();

      // Try to access Firebase only if user is logged in
      if (_userId == null) {
        debugPrint(
          '$TAG ℹ️ No user logged in, using location-based times only',
        );
        return locationPrayerTimes;
      }

      // Now try to access the database
      try {
        debugPrint(
          '$TAG 🔄 Trying to fetch prayer times from database for user: $_userId',
        );
        final QuerySnapshot snapshot = await _prayerTimesRef.get();

        if (snapshot.docs.isEmpty) {
          // If user has no prayer times set up yet, save the location-based ones
          debugPrint(
            '$TAG ℹ️ No prayer times found in database, saving location-based times',
          );
          try {
            await saveLocationBasedPrayerTimes(locationPrayerTimes);
          } catch (saveError) {
            debugPrint(
              '$TAG ❌ Failed to save location-based prayer times: $saveError',
            );
            // Continue with location-based times even if we can't save them
          }
          return locationPrayerTimes;
        } else {
          // If database has prayer times, return those
          debugPrint(
            '$TAG ✅ Found ${snapshot.docs.length} prayer times in database',
          );
          final databaseTimes =
              snapshot.docs
                  .map(
                    (doc) => PrayerTime.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Cache the database times
          _cachePrayerTimes(databaseTimes);

          // Schedule notifications for the database times
          debugPrint(
            '$TAG 🔄 Scheduling notifications for database prayer times',
          );
          for (var prayer in databaseTimes) {
            if (prayer.isEnabled) {
              await _schedulePrayerTimeNotification(prayer);
            }
          }

          return databaseTimes;
        }
      } catch (dbError) {
        // If database access fails, just use the location-based times
        debugPrint('$TAG ❌ Firebase error: $dbError');
        debugPrint(
          '$TAG ℹ️ Falling back to location-based prayer times due to database error',
        );

        // Schedule notifications for the location-based times
        debugPrint(
          '$TAG 🔄 Scheduling notifications for location-based prayer times',
        );
        for (var prayer in locationPrayerTimes) {
          if (prayer.isEnabled) {
            await _schedulePrayerTimeNotification(prayer);
          }
        }

        return locationPrayerTimes;
      }
    } catch (e) {
      debugPrint('$TAG ❌ Error getting prayer times: $e');
      // In case of permission errors or any other issues, use default prayer times
      final defaultTimes = _getDefaultPrayerTimes();

      // Schedule notifications for default times
      debugPrint('$TAG 🔄 Scheduling notifications for default prayer times');
      for (var prayer in defaultTimes) {
        if (prayer.isEnabled) {
          await _schedulePrayerTimeNotification(prayer);
        }
      }

      return defaultTimes;
    }
  }

  // Schedule all prayer time notifications
  Future<void> scheduleAllPrayerTimeNotifications() async {
    debugPrint('$TAG 🔄 Scheduling all prayer time notifications');
    final prayerTimes = await getPrayerTimes();
    for (var prayer in prayerTimes) {
      if (prayer.isEnabled) {
        await _schedulePrayerTimeNotification(prayer);
      }
    }
    debugPrint('$TAG ✅ All prayer time notifications scheduled');
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
        '$TAG Prayer notification for ${prayerTime.name} is disabled, skipping',
      );
      return;
    }

    // Ensure we have notification permissions
    try {
      final hasPermission = await _checkNotificationPermissions();
      if (!hasPermission) {
        debugPrint(
          '$TAG Cannot schedule notification: No notification permission',
        );
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
          '$TAG Scheduled prayer notification for ${prayerTime.name} at ${finalDate.toString()}, ID: $notificationId',
        );
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

  // Update all prayer times based on current location
  Future<List<PrayerTime>> updatePrayerTimesFromLocation() async {
    final locationPrayerTimes = await getPrayerTimesFromLocation();
    await saveLocationBasedPrayerTimes(locationPrayerTimes);
    return locationPrayerTimes;
  }
}
