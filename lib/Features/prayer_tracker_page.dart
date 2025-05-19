import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';

class PrayerTrackerPage extends StatefulWidget {
  const PrayerTrackerPage({super.key});

  @override
  State<PrayerTrackerPage> createState() => _PrayerTrackerPageState();
}

class _PrayerTrackerPageState extends State<PrayerTrackerPage> {
  final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final Map<String, String> prayerDescriptions = {
    'Fajr': 'Dawn Prayer',
    'Dhuhr': 'Noon Prayer',
    'Asr': 'Afternoon Prayer',
    'Maghrib': 'Sunset Prayer',
    'Isha': 'Night Prayer',
  };

  final Map<String, Color> prayerColors = {
    'Fajr': Colors.blue.shade700,
    'Dhuhr': Colors.orange,
    'Asr': Colors.green,
    'Maghrib': Colors.deepPurple,
    'Isha': Colors.indigo,
  };

  final Map<String, IconData> prayerIcons = {
    'Fajr': Icons.wb_sunny_outlined,
    'Dhuhr': Icons.wb_sunny,
    'Asr': Icons.sunny_snowing,
    'Maghrib': Icons.nightlight_round,
    'Isha': Icons.nightlight,
  };

  bool isLoading = true;
  Map<String, bool> todayPrayers = {};
  String formattedDate = '';
  int completedCount = 0;
  int streakCount = 0;

  // New fields for improved prayer tracking
  late PrayerAlarmService _prayerAlarmService;
  List<TimeOfDay> prayerTimes = [];
  bool allPrayersCompletedToday = false;
  DateTime? lastStreakUpdateDate;
  Map<String, DateTime> prayerCompletionTimes = {};

  @override
  void initState() {
    super.initState();
    _prayerAlarmService = PrayerAlarmService();
    _initPrayerTracker();
  }

  Future<void> _initPrayerTracker() async {
    setState(() => isLoading = true);

    try {
      // Get today's date in format YYYY-MM-DD
      DateTime now = DateTime.now();
      formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // Load prayer times for today
      await _loadPrayerTimes();

      // Initialize prayer status map
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to fetch today's prayer data from Firestore
        DocumentSnapshot prayerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('prayers')
                .doc(formattedDate)
                .get();

        // Initialize default values
        for (String prayer in prayerNames) {
          todayPrayers[prayer] = false;
        }

        // If prayer data exists for today, update the map
        if (prayerDoc.exists) {
          Map<String, dynamic> data = prayerDoc.data() as Map<String, dynamic>;
          for (String prayer in prayerNames) {
            todayPrayers[prayer] = data[prayer] ?? false;

            // Load prayer completion times if available
            if (data['${prayer}_completionTime'] != null) {
              prayerCompletionTimes[prayer] =
                  (data['${prayer}_completionTime'] as Timestamp).toDate();
            }
          }

          // Check if all prayers were completed today
          allPrayersCompletedToday = data['allCompleted'] ?? false;

          // Get last streak update date if available
          if (data['lastStreakUpdate'] != null) {
            lastStreakUpdateDate =
                (data['lastStreakUpdate'] as Timestamp).toDate();
          }
        }

        // Count completed prayers
        _updateCompletedCount();

        // Check for missed days and calculate streak properly
        await _calculateStreak(user.uid);
      }
    } catch (e) {
      debugPrint('Error initializing prayer tracker: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Load prayer times from the prayer alarm service
  Future<void> _loadPrayerTimes() async {
    try {
      final prayers = await _prayerAlarmService.getPrayerTimes();

      // Convert to TimeOfDay list and map to prayer names
      final times = <TimeOfDay>[];
      for (var prayer in prayers) {
        times.add(prayer.time);
      }

      setState(() {
        prayerTimes = times;
      });
    } catch (e) {
      debugPrint('Error loading prayer times: $e');
    }
  }

  void _updateCompletedCount() {
    completedCount = todayPrayers.values.where((completed) => completed).length;
  }

  Future<void> _calculateStreak(String userId) async {
    try {
      // Get user data
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        int currentStreak = userData['prayerStreak'] ?? 0;
        DateTime? lastPrayerDate;

        // Get the last prayer date if available
        if (userData['lastPrayerDate'] != null) {
          lastPrayerDate = (userData['lastPrayerDate'] as Timestamp).toDate();
        }

        // Get today's date without time
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        // Check if we need to reset the streak due to missed days
        if (lastPrayerDate != null) {
          final yesterday = today.subtract(const Duration(days: 1));
          final lastPrayerDay = DateTime(
            lastPrayerDate.year,
            lastPrayerDate.month,
            lastPrayerDate.day,
          );

          // If the last prayer date is before yesterday, reset streak
          if (lastPrayerDay.isBefore(yesterday)) {
            // Reset streak if more than one day was missed
            debugPrint('Resetting streak due to missed days');
            currentStreak = 0;

            // Update the user document with reset streak
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
                  'prayerStreak': 0,
                  'lastStreakReset': FieldValue.serverTimestamp(),
                });
          }
        }

        setState(() {
          streakCount = currentStreak;
        });
      }
    } catch (e) {
      debugPrint('Error calculating streak: $e');
    }
  }

  Future<void> _togglePrayer(String prayer) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Validate if the prayer can be toggled based on time
        if (!_canTogglePrayer(prayer)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You can only mark $prayer as completed during or after its time',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Toggle the prayer status safely without using null assertion
        final bool currentValue = todayPrayers[prayer] ?? false;
        final bool newValue = !currentValue;

        // If we're marking a prayer as completed, record the completion time
        if (newValue) {
          prayerCompletionTimes[prayer] = DateTime.now();
        } else {
          // If we're unchecking a prayer and all prayers were previously completed,
          // we need to handle this special case to prevent streak manipulation
          if (allPrayersCompletedToday &&
              completedCount == prayerNames.length) {
            // Don't allow unchecking if streak was already awarded today
            if (lastStreakUpdateDate != null) {
              final today = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );

              final streakUpdateDay = DateTime(
                lastStreakUpdateDate!.year,
                lastStreakUpdateDate!.month,
                lastStreakUpdateDate!.day,
              );

              if (streakUpdateDay.isAtSameMomentAs(today)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cannot uncheck prayers after streak has been awarded',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
            }
          }
        }

        setState(() {
          todayPrayers[prayer] = newValue;
          _updateCompletedCount();
        });

        // Prepare data to update in Firestore
        Map<String, dynamic> updateData = {...todayPrayers};

        // Add completion time if prayer was completed
        if (newValue) {
          updateData['${prayer}_completionTime'] = FieldValue.serverTimestamp();
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prayers')
            .doc(formattedDate)
            .set(updateData, SetOptions(merge: true));

        // Update streak if all prayers are completed and we haven't already done so today
        if (completedCount == prayerNames.length && !allPrayersCompletedToday) {
          // Get current streak
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

          int currentStreak = 0;
          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            currentStreak = userData['prayerStreak'] ?? 0;
          }

          // Increment streak
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'prayerStreak': currentStreak + 1,
                'lastPrayerDate': FieldValue.serverTimestamp(),
              });

          // Mark that all prayers were completed today to prevent multiple streak increments
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('prayers')
              .doc(formattedDate)
              .update({
                'allCompleted': true,
                'lastStreakUpdate': FieldValue.serverTimestamp(),
              });

          setState(() {
            streakCount = currentStreak + 1;
            allPrayersCompletedToday = true;
            lastStreakUpdateDate = DateTime.now();
          });

          // Show achievement dialog
          if (mounted) {
            _showAchievementDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling prayer: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating prayer: $e')));
      }
    }
  }

  // Check if a prayer can be toggled based on the current time
  bool _canTogglePrayer(String prayer) {
    // If we don't have prayer times yet, allow toggling
    if (prayerTimes.isEmpty || prayerTimes.length < prayerNames.length) {
      return true;
    }

    // Get the current time
    final now = TimeOfDay.now();

    // Convert to minutes for easier comparison
    final currentMinutes = now.hour * 60 + now.minute;

    // Get the index of the prayer
    final index = prayerNames.indexOf(prayer);
    if (index == -1) return true;

    // Get the prayer time
    final prayerTime = prayerTimes[index];
    final prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;

    // Allow marking prayers as completed only during or after their time
    return currentMinutes >= prayerMinutes;
  }

  void _showAchievementDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/success.json',
                    width: 120,
                    height: 120,
                    repeat: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Masha\'Allah!',
                    style: GoogleFonts.kanit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You completed all prayers today!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current streak: $streakCount days',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Alhamdulillah!',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
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
            title: Text(
              'Prayer Tracker',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date and Streak Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(DateTime.now()),
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Current streak
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Streak: $streakCount',
                                        style: GoogleFonts.kanit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Completed prayers
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$completedCount/5',
                                        style: GoogleFonts.kanit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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

                    const SizedBox(height: 20),

                    // Prayer List - Updated to match the screenshot UI
                    Expanded(
                      child: ListView.builder(
                        itemCount: prayerNames.length,
                        itemBuilder: (context, index) {
                          String prayer = prayerNames[index];
                          bool isCompleted = todayPrayers[prayer] ?? false;

                          // Use different colors for different prayers
                          Color bgColor;
                          if (prayer == 'Fajr') {
                            bgColor = Colors.blue.shade50;
                          } else if (prayer == 'Dhuhr') {
                            bgColor = Colors.orange.shade50;
                          } else if (prayer == 'Asr') {
                            bgColor = Colors.green.shade50;
                          } else if (prayer == 'Maghrib') {
                            bgColor = Colors.purple.shade50;
                          } else {
                            bgColor = Colors.indigo.shade50;
                          }

                          // Get prayer time if available
                          String prayerTimeText = '';
                          if (prayerTimes.isNotEmpty &&
                              index < prayerTimes.length) {
                            final time = prayerTimes[index];
                            final hour =
                                time.hour > 12 ? time.hour - 12 : time.hour;
                            final period = time.hour >= 12 ? 'PM' : 'AM';
                            prayerTimeText =
                                '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
                          }

                          // Check if this prayer is currently active
                          bool isActiveTime = false;
                          if (prayerTimes.isNotEmpty &&
                              index < prayerTimes.length) {
                            final now = TimeOfDay.now();
                            final currentMinutes = now.hour * 60 + now.minute;
                            final prayerMinutes =
                                prayerTimes[index].hour * 60 +
                                prayerTimes[index].minute;

                            // Prayer is active if it's within the current hour
                            isActiveTime =
                                (currentMinutes >= prayerMinutes &&
                                    currentMinutes < prayerMinutes + 60);
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            color:
                                isActiveTime ? bgColor.withAlpha(204) : bgColor,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow:
                                      isActiveTime
                                          ? [
                                            BoxShadow(
                                              color: prayerColors[prayer]!
                                                  .withAlpha(76),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Icon(
                                  prayerIcons[prayer], // Use the defined prayer icons
                                  color: prayerColors[prayer],
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                prayer,
                                style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: prayerColors[prayer],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prayerDescriptions[prayer] ?? '',
                                    style: GoogleFonts.kanit(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (prayerTimeText.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color:
                                              isActiveTime
                                                  ? Colors.green
                                                  : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          prayerTimeText,
                                          style: GoogleFonts.kanit(
                                            fontSize: 12,
                                            color:
                                                isActiveTime
                                                    ? Colors.green
                                                    : Colors.grey,
                                            fontWeight:
                                                isActiveTime
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                        if (isActiveTime)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'NOW',
                                              style: GoogleFonts.kanit(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: InkWell(
                                onTap: () => _togglePrayer(prayer),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color:
                                          isCompleted
                                              ? Colors.green
                                              : Colors.grey.shade400,
                                      width: isCompleted ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child:
                                      isCompleted
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 24,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Motivation
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '"Verily, the prayer is enjoined on the believers at fixed hours"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '- Surah An-Nisa, Verse 103',
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
