import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muslim_kids/Features/islamic_calendar_page.dart';
import 'package:muslim_kids/Features/live_classes_page.dart';
import 'package:muslim_kids/Features/notification_page.dart';
import 'package:muslim_kids/Features/prayer_alarm_page.dart';
import 'package:muslim_kids/Features/prayer_tracker_page.dart';
import 'package:muslim_kids/Features/progress_page.dart';
import 'package:muslim_kids/Features/quizzes_page.dart';
import 'package:muslim_kids/Features/settings_page.dart';
import 'package:muslim_kids/Features/videos_page.dart';
import 'package:muslim_kids/widgets/islamic_header.dart';
import 'teacher_home_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  final String userType;
  final String email;
  final String name;
  final String avatar;

  const HomePage({
    super.key,
    required this.userType,
    required this.email,
    this.name = '',
    this.avatar = 'assets/avatar2.jpg',
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          (widget.userType == 'Kid')
              ? KidHomePage(
                email: widget.email,
                name: widget.name,
                avatar: widget.avatar,
              ) // Show Kid's homepage if userType is 'Kid'
              : TeacherHomePage(
                email: widget.email,
              ), // Show Teacher's homepage if userType is 'Teacher'
    );
  }
}

class KidHomePage extends StatefulWidget {
  final String email;
  final String name;
  final String avatar;

  const KidHomePage({
    super.key,
    required this.email,
    this.name = '',
    this.avatar = 'assets/avatar2.jpg',
  });

  @override
  KidHomePageState createState() => KidHomePageState();
}

class KidHomePageState extends State<KidHomePage> {
  int _selectedIndex = 0; // Track selected index for the bottom navigation
  late final List<Widget> _pages;

  // Add controller for particles
  final List<_MagicalParticle> _particles = List.generate(
    15,
    (_) => _MagicalParticle(),
  );

  // Timer for animations
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _pages = [
      KidHomePageContent(
        initialName: widget.name,
        initialAvatar: widget.avatar,
      ),
      const ProgressPage(fromBottomNav: true),
      const SettingsPage(fromBottomNav: true),
      const NotificationPage(fromBottomNav: true),
    ];

    // Start animation timer
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        // This will trigger a rebuild with updated particle positions
      });
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  // Method to handle bottom navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Allow the body to extend behind the bottom navigation bar
      body: _pages[_selectedIndex], // Switch pages based on the selected index
      bottomNavigationBar: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Magical particles in the background
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 70),
                painter: _ParticlesPainter(_particles),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade300,
                      Colors.pink.shade200,
                      Colors.purple.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade200.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white70,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  selectedIconTheme: const IconThemeData(size: 26, grade: 200),
                  unselectedIconTheme: const IconThemeData(size: 22, grade: 0),
                  items: [
                    BottomNavigationBarItem(
                      icon: Container(
                            decoration:
                                _selectedIndex == 0
                                    ? BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(15),
                                    )
                                    : null,
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.home_rounded),
                          )
                          .animate(target: _selectedIndex == 0 ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          ),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                            decoration:
                                _selectedIndex == 1
                                    ? BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(15),
                                    )
                                    : null,
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.show_chart_rounded),
                          )
                          .animate(target: _selectedIndex == 1 ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          ),
                      label: 'Progress',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                            decoration:
                                _selectedIndex == 2
                                    ? BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(15),
                                    )
                                    : null,
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.settings_rounded),
                          )
                          .animate(target: _selectedIndex == 2 ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          ),
                      label: 'Settings',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                            decoration:
                                _selectedIndex == 3
                                    ? BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(15),
                                    )
                                    : null,
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.notifications_rounded),
                          )
                          .animate(target: _selectedIndex == 3 ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                          ),
                      label: 'Notifications',
                    ),
                  ],
                ),
              ),
            ],
          )
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideY(
            begin: 0.2,
            end: 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuad,
          ),
    );
  }
}

class KidHomePageContent extends StatefulWidget {
  final String? initialName;
  final String? initialAvatar;

  const KidHomePageContent({super.key, this.initialName, this.initialAvatar});

  @override
  State<KidHomePageContent> createState() => _KidHomePageContentState();
}

class _KidHomePageContentState extends State<KidHomePageContent> {
  String? userName;
  String? userAvatar;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use initial values if provided
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      userName = widget.initialName;
      isLoading = false;
    }
    if (widget.initialAvatar != null && widget.initialAvatar!.isNotEmpty) {
      userAvatar = widget.initialAvatar;
      isLoading = false;
    }

    // Still load from Firestore to get the most up-to-date data
    _loadUserData();
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      Fluttertoast.showToast(
        msg: "Logged out successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 18.0,
        toastLength: Toast.LENGTH_SHORT,
      );

      // Navigate to login page by popping until the first route
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error logging out: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 18.0,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = userData['name'] ?? 'User';
            userAvatar = userData['avatar'] ?? 'assets/avatar2.jpg';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<String> carouselImages = const [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
  ];

  final List<Map<String, dynamic>> tiles = const [
    {
      'title': 'Prayer Alarm',
      'image': 'assets/prayer_time.jpg',
      'color': Colors.deepOrangeAccent,
      'page': PrayerAlarmPage(),
    },
    {
      'title': 'Quizzes',
      'image': 'assets/quizzes.jpg',
      'color': Colors.orange,
      'page': QuizzesPage(),
    },
    {
      'title': 'Videos',
      'image': 'assets/videos.jpg',
      'color': Colors.deepPurpleAccent,
      'page': VideosPage(),
    },
    {
      'title': 'Live Classes',
      'image': 'assets/live_classes.jpg',
      'color': Colors.blue,
      'page': LiveClassesPage(),
    },
    {
      'title': 'Islamic Calendar',
      'image': 'assets/islamic_calendar.jpg',
      'color': Colors.green,
      'page': IslamicCalendarPage(),
    },
    {
      'title': 'Prayer Tracker',
      'image': 'assets/prayer_tracker.jpg',
      'color': Colors.pink,
      'page': PrayerTrackerPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      extendBody:
          true, // Make the body content extend behind the bottomNavigationBar
      appBar: IslamicHeader(
        avatarPath: userAvatar,
        userName: userName ?? 'User',
        isLoading: isLoading,
        onLogoutPressed: _logout,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 250.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                  ),
                  items:
                      carouselImages.map((image) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.asset(
                            image,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => tiles[index]['page'],
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: tiles[index]['color'],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(tiles[index]['image'], height: 60),
                            const SizedBox(height: 5),
                            Text(
                              tiles[index]['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Magical particle class for bottom navigation animation
class _MagicalParticle {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speed;

  _MagicalParticle() {
    reset();
  }

  void reset() {
    x = Random().nextDouble() * 500;
    y = Random().nextDouble() * 60;
    size = Random().nextDouble() * 4 + 1;

    // Create magical colors
    final colors = [
      Colors.pink.shade100,
      Colors.purple.shade100,
      Colors.white,
      Colors.purple.shade200,
      Colors.pink.shade200,
    ];

    color = colors[Random().nextInt(colors.length)].withOpacity(
      Random().nextDouble() * 0.7 + 0.3,
    );

    speed = Random().nextDouble() * 1 + 0.5;
  }

  void update() {
    y -= speed;

    // Reset particle when it reaches the top
    if (y < 0) {
      reset();
      y = 60;
    }
  }
}

// Painter to draw the magical particles
class _ParticlesPainter extends CustomPainter {
  final List<_MagicalParticle> particles;

  _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Update particle positions
    for (var particle in particles) {
      particle.update();

      final paint =
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x % size.width, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
