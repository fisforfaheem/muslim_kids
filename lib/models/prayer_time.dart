
import 'package:flutter/material.dart';

class PrayerTime {
  final String id;
  final String name;
  final TimeOfDay time;
  final bool isEnabled;
  final bool adhanEnabled;
  final String adhanType;
  final List<String> daysOfWeek;

  PrayerTime({
    required this.id,
    required this.name,
    required this.time,
    this.isEnabled = true,
    this.adhanEnabled = true,
    this.adhanType = 'default',
    this.daysOfWeek = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ],
  });

  // Convert TimeOfDay to string for storage
  String get timeString =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Factory method to create PrayerTime from a map (for Firestore)
  factory PrayerTime.fromMap(Map<String, dynamic> map, String id) {
    // Parse the time string into a TimeOfDay object
    final List<String> timeParts = (map['time'] as String).split(':');
    final TimeOfDay time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return PrayerTime(
      id: id,
      name: map['name'] ?? '',
      time: time,
      isEnabled: map['isEnabled'] ?? true,
      adhanEnabled: map['adhanEnabled'] ?? true,
      adhanType: map['adhanType'] ?? 'default',
      daysOfWeek: List<String>.from(map['daysOfWeek'] ?? []),
    );
  }

  // Convert PrayerTime to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': timeString,
      'isEnabled': isEnabled,
      'adhanEnabled': adhanEnabled,
      'adhanType': adhanType,
      'daysOfWeek': daysOfWeek,
    };
  }

  // Create a copy of this PrayerTime with updated fields
  PrayerTime copyWith({
    String? id,
    String? name,
    TimeOfDay? time,
    bool? isEnabled,
    bool? adhanEnabled,
    String? adhanType,
    List<String>? daysOfWeek,
  }) {
    return PrayerTime(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      adhanType: adhanType ?? this.adhanType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }
}
