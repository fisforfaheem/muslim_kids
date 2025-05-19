import 'package:flutter/material.dart';
import 'package:muslim_kids/models/prayer_time.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Color(0xFF43A047), // Nice green color
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_hasLocationPermission)
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child:
                  _isRefreshing
                      ? Container(
                        key: ValueKey('refreshing'),
                        padding: EdgeInsets.all(8),
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : IconButton(
                        key: ValueKey('location'),
                        icon: Icon(Icons.my_location),
                        onPressed: _refreshPrayerTimes,
                        tooltip: 'Update prayer times based on location',
                      ),
            ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF43A047).withAlpha(50),
              Color(0xFF2E7D32).withAlpha(50),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location refresh button
            if (_hasLocationPermission)
              FloatingActionButton(
                heroTag: 'location_btn',
                backgroundColor: Color(0xFF43A047),
                elevation: 4,
                onPressed: _isRefreshing ? null : _refreshPrayerTimes,
                mini: true,
                tooltip: 'Update times based on location',
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    _isRefreshing ? Icons.sync : Icons.my_location,
                    key: ValueKey(_isRefreshing ? 'sync' : 'location'),
                    color: Colors.white,
                  ),
                ),
              ),
            SizedBox(height: 10),
            // Notification refresh button
            FloatingActionButton(
              heroTag: 'notification_btn',
              backgroundColor: Color(0xFF2E7D32),
              elevation: 4,
              onPressed: () async {
                // Capture the context before the async gap
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Show loading indicator
                scaffoldMessenger.showSnackBar(
                  SnackBar(
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
                    backgroundColor: Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                // Reschedule all notifications
                await _alarmService.scheduleAllPrayerTimeNotifications();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 16),
                          Text('Prayer alarms updated successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Reschedule all notifications',
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Light green at top
              Color(0xFFC8E6C9), // Lighter green at bottom
            ],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF43A047),
                        ),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Loading prayer times...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _refreshPrayerTimes,
                  color: Color(0xFF43A047),
                  backgroundColor: Colors.white,
                  strokeWidth: 3,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location and date card with animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 3,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withAlpha(230),
                                        Colors.white.withAlpha(180),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Location row
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  _hasLocationPermission
                                                      ? Colors.green.withAlpha(
                                                        30,
                                                      )
                                                      : Colors.orange.withAlpha(
                                                        30,
                                                      ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _hasLocationPermission
                                                  ? Icons.location_on
                                                  : Icons.location_disabled,
                                              size: 18,
                                              color:
                                                  _hasLocationPermission
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _hasLocationPermission
                                                      ? 'Location Enabled'
                                                      : 'Location Disabled',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!_hasLocationPermission)
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final hasPermission =
                                                    await _alarmService
                                                        .checkLocationPermission();
                                                if (mounted) {
                                                  setState(() {
                                                    _hasLocationPermission =
                                                        hasPermission;
                                                  });
                                                }
                                                if (hasPermission) {
                                                  _refreshPrayerTimes();
                                                } else {
                                                  await Geolocator.openAppSettings();
                                                }
                                              },
                                              icon: Icon(
                                                Icons.location_searching,
                                                size: 16,
                                              ),
                                              label: Text('Enable'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange.shade600,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                textStyle: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      Divider(height: 24),

                                      // Date information
                                      Row(
                                        children: [
                                          // Hijri date
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month,
                                                      size: 16,
                                                      color: Color(0xFF43A047),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Hijri Date',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${_hijriDate.hDay} ${_hijriDate.longMonthName} ${_hijriDate.hYear}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Gregorian date
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.today,
                                                      size: 16,
                                                      color: Color(0xFF43A047),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Gregorian Date',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  DateFormat(
                                                    'MMMM dd, yyyy',
                                                  ).format(_today),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            // Next prayer circular display
                            if (_nextPrayer != null)
                              Center(
                                child: Column(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
                                      duration: Duration(milliseconds: 800),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getPrayerCardColor(
                                            _nextPrayer!.name,
                                          ).withAlpha(50),
                                          border: Border.all(
                                            color: _getPrayerCardColor(
                                              _nextPrayer!.name,
                                            ),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getPrayerCardColor(
                                                _nextPrayer!.name,
                                              ).withAlpha(100),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            // Animated circular progress indicator
                                            Center(
                                              child: TweenAnimationBuilder<
                                                double
                                              >(
                                                tween: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                duration: Duration(seconds: 2),
                                                builder: (
                                                  context,
                                                  value,
                                                  child,
                                                ) {
                                                  return CircularProgressIndicator(
                                                    value: value,
                                                    strokeWidth: 2,
                                                    backgroundColor: Colors
                                                        .white
                                                        .withAlpha(100),
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          _getPrayerCardColor(
                                                            _nextPrayer!.name,
                                                          ),
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // Prayer information
                                            Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _nextPrayer!.name,
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${_nextPrayer!.time.hour > 12 ? (_nextPrayer!.time.hour - 12).toString() : _nextPrayer!.time.hour.toString()}:${_nextPrayer!.time.minute.toString().padLeft(2, '0')} ${_nextPrayer!.time.hour >= 12 ? "PM" : "AM"}',
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      'Next Prayer',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[800],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                                    color: Color(0xFF43A047),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
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
                                      await _alarmService
                                          .checkLocationPermission();
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children:
                                                      _prayerTimes
                                                          .map(
                                                            (
                                                              prayer,
                                                            ) => ListTile(
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
                                                                onChanged: (
                                                                  value,
                                                                ) {
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
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text("Close"),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                    icon: Icon(Icons.view_list),
                                    label: Text("Show All Prayer Times"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF43A047),
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
                ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF43A047),
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

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isNext ? 4 : 2,
        shadowColor: isNext ? backgroundColor.withAlpha(100) : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              isNext
                  ? BorderSide(color: backgroundColor, width: 2)
                  : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor.withAlpha(70),
                backgroundColor.withAlpha(40),
              ],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prayer icon with animation
              Hero(
                tag: 'prayer_icon_${prayer.id}',
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withAlpha(80),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: backgroundColor, size: 24),
                ),
              ),
              SizedBox(width: 16),

              // Prayer name and time - using Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with flexible text
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Time for ${prayer.name} Prayer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 2),
                              ],
                            ),
                            child: Text(
                              "NEXT",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: backgroundColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),

                    // Subtitle with overflow protection
                    Text(
                      isPast
                          ? "Time for ${prayer.name} Prayer has passed"
                          : "It's time to pray ${prayer.name}",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    SizedBox(height: 6),

                    // Time information with overflow protection
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
                        Flexible(
                          child: Text(
                            timeStatus,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Toggle switch
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: prayer.isEnabled,
                  onChanged: (value) => _togglePrayerTime(prayer, value),
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
