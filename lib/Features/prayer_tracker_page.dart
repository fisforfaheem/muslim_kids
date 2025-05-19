import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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
    'Isha': 'Night Prayer'
  };

  final Map<String, Color> prayerColors = {
    'Fajr': Colors.blue.shade700,
    'Dhuhr': Colors.orange,
    'Asr': Colors.green,
    'Maghrib': Colors.deepPurple,
    'Isha': Colors.indigo
  };

  final Map<String, IconData> prayerIcons = {
    'Fajr': Icons.wb_sunny_outlined,
    'Dhuhr': Icons.wb_sunny,
    'Asr': Icons.sunny_snowing,
    'Maghrib': Icons.nightlight_round,
    'Isha': Icons.nightlight
  };

  bool isLoading = true;
  Map<String, bool> todayPrayers = {};
  String formattedDate = '';
  int completedCount = 0;
  int streakCount = 0;

  @override
  void initState() {
    super.initState();
    _initPrayerTracker();
  }

  Future<void> _initPrayerTracker() async {
    setState(() => isLoading = true);

    try {
      // Get today's date in format YYYY-MM-DD
      DateTime now = DateTime.now();
      formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // Initialize prayer status map
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to fetch today's prayer data from Firestore
        DocumentSnapshot prayerDoc = await FirebaseFirestore.instance
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
          }
        }

        // Count completed prayers
        _updateCompletedCount();

        // Get streak data
        await _calculateStreak(user.uid);
      }
    } catch (e) {
      print('Error initializing prayer tracker: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateCompletedCount() {
    completedCount = todayPrayers.values.where((completed) => completed).length;
  }

  Future<void> _calculateStreak(String userId) async {
    try {
      // Get streak from user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          streakCount = userData['prayerStreak'] ?? 0;
        });
      }
    } catch (e) {
      print('Error calculating streak: $e');
    }
  }

  Future<void> _togglePrayer(String prayer) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Toggle the prayer status safely without using null assertion
        final bool currentValue = todayPrayers[prayer] ?? false;
        setState(() {
          todayPrayers[prayer] = !currentValue;
          _updateCompletedCount();
        });

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prayers')
            .doc(formattedDate)
            .set(todayPrayers, SetOptions(merge: true));

        // Update streak if all prayers are completed
        if (completedCount == prayerNames.length) {
          // Get current streak
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
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
              .update({'prayerStreak': currentStreak + 1});

          setState(() {
            streakCount = currentStreak + 1;
          });

          // Show achievement dialog
          if (mounted) {
            _showAchievementDialog();
          }
        }
      }
    } catch (e) {
      print('Error toggling prayer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating prayer: $e')),
      );
    }
  }

  void _showAchievementDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                style: GoogleFonts.kanit(
                  fontSize: 18,
                ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
      body: isLoading
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
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(DateTime.now()),
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

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          color: bgColor,
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
                              ),
                              child: Icon(
                                prayer == 'Fajr'
                                    ? Icons.wb_sunny_outlined
                                    : prayer == 'Dhuhr'
                                        ? Icons.wb_sunny
                                        : prayer == 'Asr'
                                            ? Icons.wb_sunny_outlined
                                            : Icons.nightlight_round,
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
                            subtitle: Text(
                              prayerDescriptions[prayer] ?? '',
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: InkWell(
                              onTap: () => _togglePrayer(prayer),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: isCompleted
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
