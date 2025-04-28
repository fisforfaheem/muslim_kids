import 'package:flutter/material.dart';
import 'package:muslim_kids/models/prayer_time.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPrayerTimes();
  }

  Future<void> _checkPermissions() async {
    // Check notification permission
    final status = await Permission.notification.status;
    setState(() {
      _hasNotificationPermission = status.isGranted;
    });

    // Request notification permission if not granted
    if (!status.isGranted) {
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
      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _toggleAdhan(PrayerTime prayerTime, bool isEnabled) async {
    final updatedPrayerTime = prayerTime.copyWith(adhanEnabled: isEnabled);

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
              primary: Colors.pink[200]!,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.pink[200],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Prayer Alarms',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9AA2)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Animated header
                  SizedBox(
                    height: 160,
                    child: Lottie.asset(
                      'assets/prayer_alarm.json',
                      fit: BoxFit.contain,
                    ),
                  ),

                  if (!_hasNotificationPermission)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Notification Permission Required',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please enable notifications to receive prayer time alerts',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _checkPermissions();
                                if (!_hasNotificationPermission) {
                                  await openAppSettings();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[200],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Grant Permission'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Set your prayer time alarms',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Prayer times list
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _prayerTimes.length,
                    itemBuilder: (context, index) {
                      final prayerTime = _prayerTimes[index];
                      return _buildPrayerTimeCard(prayerTime);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Note about background notifications
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.pink[200]),
                              const SizedBox(width: 8),
                              Text(
                                'Important Information',
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prayer alarms will work even when the app is closed. Make sure notifications are enabled in your device settings to receive prayer time alerts.',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Note about Firestore permissions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.amber[800]),
                              const SizedBox(width: 8),
                              Text(
                                'Note About Cloud Sync',
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your prayer times are currently stored locally. If you see a "permission denied" message, don\'t worry - your alarms will still work, but changes won\'t be saved to the cloud until permissions are configured.',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink[200],
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
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildPrayerTimeCard(PrayerTime prayerTime) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.pink[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prayer name
                  Text(
                    prayerTime.name,
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  // Prayer time
                  GestureDetector(
                    onTap: () => _updatePrayerTime(prayerTime),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.pink[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${prayerTime.time.hour.toString().padLeft(2, '0')}:${prayerTime.time.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Enable/disable alarm
                  Row(
                    children: [
                      Text(
                        'Alarm',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: prayerTime.isEnabled,
                        onChanged: (value) =>
                            _togglePrayerTime(prayerTime, value),
                        activeColor: Colors.pink[200],
                      ),
                    ],
                  ),

                  // Enable/disable adhan
                  Row(
                    children: [
                      Text(
                        'Adhan',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: prayerTime.adhanEnabled,
                        onChanged: (value) => _toggleAdhan(prayerTime, value),
                        activeColor: Colors.pink[200],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
