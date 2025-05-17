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
  List<PrayerTime> _relevantPrayers = [];
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
    _hijriDate = HijriCalendar.fromDate(DateTime.now());
    _today = DateTime.now();
    _checkPermissions();
    _loadPrayerTimes();
  }

  Future<void> _checkPermissions() async {
    // Check notification permission
    final notificationStatus = await Permission.notification.status;

    // Check location permission
    final locationPermission = await _alarmService.checkLocationPermission();

    if (mounted) {
      setState(() {
        _hasNotificationPermission = notificationStatus.isGranted;
        _hasLocationPermission = locationPermission;
      });
    }

    // Request notification permission if not granted
    if (!notificationStatus.isGranted) {
      final result = await Permission.notification.request();
      if (mounted) {
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
      }
    }
  }

  Future<void> _loadPrayerTimes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prayerTimes = await _alarmService.getPrayerTimes();
      _locationName = _alarmService.locationName;

      if (!mounted) return;

      setState(() {
        _prayerTimes = prayerTimes;
        _filterRelevantPrayers();
        _findNextPrayer();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load prayer times'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterRelevantPrayers() {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Sort prayer times by time
    _prayerTimes.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    // Get current and upcoming prayers
    _relevantPrayers =
        _prayerTimes.where((prayer) {
          final prayerMinutes = prayer.time.hour * 60 + prayer.time.minute;

          // Keep prayer if:
          // 1. It's less than 1 hour in the past, or
          // 2. It's in the future (today)
          return (currentMinutes - prayerMinutes < 60 &&
                  currentMinutes - prayerMinutes >= 0) ||
              prayerMinutes > currentMinutes;
        }).toList();

    // If no relevant prayers found (late at night), show only the next day's first prayer
    if (_relevantPrayers.isEmpty && _prayerTimes.isNotEmpty) {
      _relevantPrayers = [_prayerTimes.first];
    }
  }

  Future<void> _refreshPrayerTimes() async {
    if (!_hasLocationPermission) {
      final hasPermission = await _alarmService.checkLocationPermission();
      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to update prayer times',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final prayerTimes = await _alarmService.updatePrayerTimesFromLocation();
      _locationName = _alarmService.locationName;

      if (mounted) {
        setState(() {
          _prayerTimes = prayerTimes;
          _filterRelevantPrayers();
          _findNextPrayer();
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer times updated based on your location'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

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

    if (mounted) {
      setState(() {
        final index = _prayerTimes.indexWhere(
          (time) => time.id == prayerTime.id,
        );
        if (index != -1) {
          _prayerTimes[index] = updatedPrayerTime;
        }

        // Also update in relevant prayers
        final relevantIndex = _relevantPrayers.indexWhere(
          (time) => time.id == prayerTime.id,
        );
        if (relevantIndex != -1) {
          _relevantPrayers[relevantIndex] = updatedPrayerTime;
        }
      });
    }

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

      if (mounted) {
        setState(() {
          final index = _prayerTimes.indexWhere(
            (time) => time.id == prayerTime.id,
          );
          if (index != -1) {
            _prayerTimes[index] = updatedPrayerTime;
          }

          // Also update in relevant prayers
          final relevantIndex = _relevantPrayers.indexWhere(
            (time) => time.id == prayerTime.id,
          );
          if (relevantIndex != -1) {
            _relevantPrayers[relevantIndex] = updatedPrayerTime;
          }
        });
      }

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
          'Prayer Times',
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
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Loading prayer times...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshPrayerTimes,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                color:
                                    _hasLocationPermission
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
                                    final hasPermission =
                                        await _alarmService
                                            .checkLocationPermission();
                                    if (mounted) {
                                      setState(() {
                                        _hasLocationPermission = hasPermission;
                                      });
                                    }
                                    if (hasPermission) {
                                      _refreshPrayerTimes();
                                    } else {
                                      await Geolocator.openAppSettings();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
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
                                    color: _getPrayerCardColor(
                                      _nextPrayer!.name,
                                    ).withOpacity(0.2),
                                    border: Border.all(
                                      color: _getPrayerCardColor(
                                        _nextPrayer!.name,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _nextPrayer!.name,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_nextPrayer!.time.hour > 12 ? (_nextPrayer!.time.hour - 12).toString() : _nextPrayer!.time.hour.toString()}:${_nextPrayer!.time.minute.toString().padLeft(2, '0')} ${_nextPrayer!.time.hour >= 12 ? "PM" : "AM"}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Next Prayer',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
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

                        // Prayer notifications heading
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_alarm,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Prayer Notifications",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Relevant prayer times
                        if (_relevantPrayers.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "No upcoming prayer times",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _relevantPrayers.length,
                            itemBuilder: (context, index) {
                              final prayer = _relevantPrayers[index];
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
                              if (mounted) {
                                setState(() {
                                  _hasLocationPermission = hasPermission;
                                });
                              }
                              if (!hasPermission) {
                                await Geolocator.openAppSettings();
                              } else {
                                _refreshPrayerTimes();
                              }
                            },
                          ),

                        // Button to show all prayer times
                        if (_prayerTimes.length > _relevantPrayers.length)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text("All Prayer Times"),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children:
                                                  _prayerTimes
                                                      .map(
                                                        (prayer) => ListTile(
                                                          leading: Icon(
                                                            _getPrayerIcon(
                                                              prayer.name,
                                                            ),
                                                          ),
                                                          title: Text(
                                                            prayer.name,
                                                          ),
                                                          subtitle: Text(
                                                            '${prayer.time.hour > 12 ? (prayer.time.hour - 12).toString() : prayer.time.hour.toString()}:${prayer.time.minute.toString().padLeft(2, '0')} ${prayer.time.hour >= 12 ? "PM" : "AM"}',
                                                          ),
                                                          trailing: Switch(
                                                            value:
                                                                prayer
                                                                    .isEnabled,
                                                            onChanged: (value) {
                                                              _togglePrayerTime(
                                                                prayer,
                                                                value,
                                                              );
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: Text("Close"),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                icon: Icon(Icons.view_list),
                                label: Text("Show All Prayer Times"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 24),
                      ],
                    ),
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
            onPressed: () async {
              // Capture the context before the async gap
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Show loading indicator
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Updating prayer alarms...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.blue,
                ),
              );

              // Reschedule all notifications
              await _alarmService.scheduleAllPrayerTimeNotifications();

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 16),
                        Text('Prayer alarms updated successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(message),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final prayerMinutes = prayer.time.hour * 60 + prayer.time.minute;
    final isPast = prayerMinutes < currentMinutes;
    final isNext = _nextPrayer?.id == prayer.id;

    // Calculate time difference
    String timeStatus;
    final difference = (prayerMinutes - currentMinutes).abs();

    if (isPast) {
      if (difference < 60) {
        timeStatus = "${difference}min ago";
      } else {
        timeStatus = "${difference ~/ 60}h ${difference % 60}min ago";
      }
    } else {
      if (difference < 60) {
        timeStatus = "in ${difference}min";
      } else {
        timeStatus = "in ${difference ~/ 60}h ${difference % 60}min";
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isNext ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isNext ? BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      color: isNext ? backgroundColor : backgroundColor.withAlpha(180),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Prayer icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(77),
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
                  Row(
                    children: [
                      Text(
                        "Time for ${prayer.name} Prayer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (isNext) SizedBox(width: 8),
                      if (isNext)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "NEXT",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    isPast
                        ? "Time for ${prayer.name} Prayer has passed"
                        : "It's time to pray ${prayer.name}",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${prayer.time.hour > 12 ? (prayer.time.hour - 12).toString() : prayer.time.hour.toString()}:${prayer.time.minute.toString().padLeft(2, '0')} ${prayer.time.hour >= 12 ? "PM" : "AM"}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        timeStatus,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle switch
            Switch(
              value: prayer.isEnabled,
              onChanged: (value) => _togglePrayerTime(prayer, value),
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.withAlpha(128),
            ),
          ],
        ),
      ),
    );
  }
}
