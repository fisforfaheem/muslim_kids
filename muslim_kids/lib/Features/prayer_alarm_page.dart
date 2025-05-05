import 'package:flutter/material.dart';
import 'package:muslim_kids/models/prayer_time.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geolocator/geolocator.dart';

class PrayerAlarmPage extends StatefulWidget {
  const PrayerAlarmPage({super.key});

  @override
  State<PrayerAlarmPage> createState() => _PrayerAlarmPageState();
}

class _PrayerAlarmPageState extends State<PrayerAlarmPage> {
  final PrayerAlarmService _alarmService = PrayerAlarmService();
  List<PrayerTime> _prayerTimes = [];
  bool _isLoading = true;
  bool _hasNotificationPermission = false;
  bool _hasLocationPermission = false;
  bool _isRefreshing = false;
  PrayerTime? _nextPrayer;
  late HijriCalendar _hijriDate;
  late DateTime _today;
  String _locationName = "Unknown Location";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPrayerTimes();
    _today = DateTime.now();
    _hijriDate = HijriCalendar.fromDate(_today);
  }

  Future<void> _checkPermissions() async {
    // Check notification permission
    final notificationStatus = await Permission.notification.status;

    // Check location permission
    final locationPermission = await _alarmService.checkLocationPermission();

    setState(() {
      _hasNotificationPermission = notificationStatus.isGranted;
      _hasLocationPermission = locationPermission;
    });

    // Request notification permission if not granted
    if (!notificationStatus.isGranted) {
      final result = await Permission.notification.request();
      setState(() {
        _hasNotificationPermission = result.isGranted;
      });
    }
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerTimes = await _alarmService.getPrayerTimes();
      _locationName = _alarmService.locationName;

      setState(() {
        _prayerTimes = prayerTimes;
        _findNextPrayer();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load prayer times'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshPrayerTimes() async {
    if (!_hasLocationPermission) {
      final hasPermission = await _alarmService.checkLocationPermission();
      setState(() {
        _hasLocationPermission = hasPermission;
      });

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission is required to update prayer times'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final prayerTimes = await _alarmService.updatePrayerTimesFromLocation();
      _locationName = _alarmService.locationName;

      setState(() {
        _prayerTimes = prayerTimes;
        _findNextPrayer();
        _isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer times updated based on your location'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update prayer times'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _findNextPrayer() {
    if (_prayerTimes.isEmpty) return;

    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Sort prayer times by time
    _prayerTimes.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    // Find the next prayer
    _nextPrayer = null;
    for (final prayer in _prayerTimes) {
      final prayerMinutes = prayer.time.hour * 60 + prayer.time.minute;
      if (prayerMinutes > currentMinutes) {
        _nextPrayer = prayer;
        break;
      }
    }

    // If all prayers for today have passed, next prayer is first prayer tomorrow
    if (_nextPrayer == null && _prayerTimes.isNotEmpty) {
      _nextPrayer = _prayerTimes.first;
    }
  }

  Future<void> _togglePrayerTime(PrayerTime prayerTime, bool isEnabled) async {
    final updatedPrayerTime = prayerTime.copyWith(isEnabled: isEnabled);

    setState(() {
      final index = _prayerTimes.indexWhere((time) => time.id == prayerTime.id);
      if (index != -1) {
        _prayerTimes[index] = updatedPrayerTime;
      }
    });

    await _alarmService.updatePrayerTime(updatedPrayerTime);
  }

  Future<void> _updatePrayerTime(PrayerTime prayerTime) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: prayerTime.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newTime != null) {
      final updatedPrayerTime = prayerTime.copyWith(time: newTime);

      setState(() {
        final index =
            _prayerTimes.indexWhere((time) => time.id == prayerTime.id);
        if (index != -1) {
          _prayerTimes[index] = updatedPrayerTime;
        }
      });

      await _alarmService.updatePrayerTime(updatedPrayerTime);
      _findNextPrayer();
    }
  }

  Color _getPrayerCardColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Colors.green.shade300;
      case 'dhuhr':
        return Colors.green.shade400;
      case 'asr':
        return Colors.pink.shade200;
      case 'maghrib':
        return Colors.orange.shade300;
      case 'isha':
        return Colors.purple.shade200;
      default:
        return Colors.blue.shade200;
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.wb_twilight;
      case 'isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prayer Alarm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (_hasLocationPermission)
            IconButton(
              icon: Icon(_isRefreshing ? Icons.sync : Icons.my_location),
              onPressed: _isRefreshing ? null : _refreshPrayerTimes,
              tooltip: 'Update prayer times based on location',
            ),
        ],
      ),
      backgroundColor: Color(0xFFFFF9C4), // Light yellow background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location name
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _hasLocationPermission
                                ? Icons.location_on
                                : Icons.location_disabled,
                            size: 16,
                            color: _hasLocationPermission
                                ? Colors.green
                                : Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!_hasLocationPermission)
                            TextButton(
                              onPressed: () async {
                                final hasPermission = await _alarmService
                                    .checkLocationPermission();
                                setState(() {
                                  _hasLocationPermission = hasPermission;
                                });
                                if (hasPermission) {
                                  _refreshPrayerTimes();
                                } else {
                                  await Geolocator.openAppSettings();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0),
                                minimumSize: Size(0, 0),
                              ),
                              child: Text(
                                'Enable',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Hijri date display
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Hijri ${_hijriDate.hDay} ${_hijriDate.longMonthName} ${_hijriDate.hYear}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Today's gregorian date
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_today),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Next prayer circular display
                    if (_nextPrayer != null)
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.purple,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _nextPrayer!.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_nextPrayer!.time.hour.toString().padLeft(2, '0')}:${_nextPrayer!.time.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Next Prayer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 24),

                    // Today's prayers heading
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Today's Prayers",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Prayer times list
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _prayerTimes.length,
                      itemBuilder: (context, index) {
                        final prayer = _prayerTimes[index];
                        return _buildPrayerCard(prayer);
                      },
                    ),

                    SizedBox(height: 24),

                    // Permission warnings if needed
                    if (!_hasNotificationPermission)
                      _buildPermissionCard(
                        title: 'Notification Permission Required',
                        message:
                            'Please enable notifications to receive prayer time alerts',
                        icon: Icons.notifications_off,
                        buttonText: 'Grant Permission',
                        onPressed: () async {
                          await _checkPermissions();
                          if (!_hasNotificationPermission) {
                            await openAppSettings();
                          }
                        },
                      ),

                    if (!_hasLocationPermission)
                      _buildPermissionCard(
                        title: 'Location Permission Required',
                        message:
                            'Please enable location services to get accurate prayer times for your area',
                        icon: Icons.location_disabled,
                        buttonText: 'Grant Permission',
                        onPressed: () async {
                          final hasPermission =
                              await _alarmService.checkLocationPermission();
                          setState(() {
                            _hasLocationPermission = hasPermission;
                          });
                          if (!hasPermission) {
                            await Geolocator.openAppSettings();
                          } else {
                            _refreshPrayerTimes();
                          }
                        },
                      ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location refresh button
          if (_hasLocationPermission)
            FloatingActionButton(
              heroTag: 'location_btn',
              backgroundColor: Colors.green,
              onPressed: _isRefreshing ? null : _refreshPrayerTimes,
              mini: true,
              tooltip: 'Update times based on location',
              child: Icon(
                _isRefreshing ? Icons.sync : Icons.my_location,
                color: Colors.white,
              ),
            ),
          SizedBox(height: 10),
          // Notification refresh button
          FloatingActionButton(
            heroTag: 'notification_btn',
            backgroundColor: Colors.blue,
            onPressed: () {
              // Reschedule all notifications
              _alarmService.scheduleAllPrayerTimeNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prayer alarms updated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Reschedule all notifications',
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String message,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      color: Colors.amber[100],
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(message),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerTime prayer) {
    final backgroundColor = _getPrayerCardColor(prayer.name);
    final icon = _getPrayerIcon(prayer.name);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Prayer icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 16),

            // Prayer name and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')} ${prayer.time.hour >= 12 ? "PM" : "AM"}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle switch
            Switch(
              value: prayer.isEnabled,
              onChanged: (value) => _togglePrayerTime(prayer, value),
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
