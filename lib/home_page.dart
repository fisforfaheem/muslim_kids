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
import 'package:muslim_kids/quiz_debug_screen.dart';
import 'package:muslim_kids/add_multiple_quizzes.dart';
import 'teacher_home_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:async';

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
  }

  @override
  void dispose() {
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
      bottomNavigationBar: OptimizedParticleSystem(
            child: ImprovedBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
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
    if (!mounted) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // Add timeout to prevent hanging requests
      final userDoc = await Future.any([
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),
        Future.delayed(
          const Duration(seconds: 5),
          () => throw TimeoutException('Request timed out'),
        ),
      ]);

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = userData['name'] ?? 'User';
          userAvatar = userData['avatar'] ?? 'assets/avatar2.jpg';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  final List<String> carouselImages = const [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
  ];

  List<Map<String, dynamic>> get tiles => [
    {
      'title': 'Prayer Alarm',
      'image': 'assets/prayer_time.jpg',
      'color': Colors.deepOrangeAccent,
      'page': const PrayerAlarmPage(),
    },
    {
      'title': 'Quizzes',
      'image': 'assets/quizzes.jpg',
      'color': Colors.orange,
      'page': const QuizzesPage(),
    },
    {
      'title': 'Videos',
      'image': 'assets/videos.jpg',
      'color': Colors.deepPurpleAccent,
      'page': const VideosPage(),
    },
    {
      'title': 'Live Classes',
      'image': 'assets/live_classes.jpg',
      'color': Colors.blue,
      'page': const LiveClassesPage(),
    },
    {
      'title': 'Islamic Calendar',
      'image': 'assets/islamic_calendar.jpg',
      'color': Colors.green,
      'page': const IslamicCalendarPage(),
    },
    {
      'title': 'Prayer Tracker',
      'image': 'assets/prayer_tracker.jpg',
      'color': Colors.pink,
      'page': const PrayerTrackerPage(),
    },

    // Debug tile - only visible in development
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      extendBody: true,
      appBar: IslamicHeader(
        avatarPath: userAvatar,
        userName: userName ?? 'User',
        isLoading: isLoading,
        onLogoutPressed: _logout,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 255, 244, 143),
              const Color.fromARGB(255, 255, 230, 100),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -20,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                                "Welcome to Muslim Kids!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                  letterSpacing: 0.5,
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: const Duration(milliseconds: 600),
                              )
                              .shimmer(
                                delay: const Duration(milliseconds: 1200),
                                duration: const Duration(milliseconds: 1800),
                              ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: CarouselSlider(
                        options: CarouselOptions(
                          height: 250.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          autoPlayAnimationDuration: const Duration(
                            milliseconds: 800,
                          ),
                          autoPlayCurve: Curves.easeInOut,
                          pauseAutoPlayOnTouch: true,
                        ),
                        items:
                            carouselImages.map((image) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 5.0,
                                      spreadRadius: 1.0,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.asset(
                                    image,
                                    fit:
                                        BoxFit
                                            .contain, // Changed to contain to show full image
                                    width: double.infinity,
                                    height: 250.0,
                                    cacheWidth: 800,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width < 360
                                        ? 2
                                        : 3,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio:
                                    MediaQuery.of(context).size.width < 360
                                        ? 0.9
                                        : 0.8,
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
                                      gradient: LinearGradient(
                                        colors: [
                                          (tiles[index]['color'] as Color)
                                              .withAlpha(180),
                                          tiles[index]['color'] as Color,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (tiles[index]['color']
                                                  as Color)
                                              .withAlpha(100),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(2, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withAlpha(50),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(50),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.asset(
                                            tiles[index]['image'],
                                            height: 50,
                                            width: 50,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          tiles[index]['title'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 2,
                                                color: Color.fromARGB(
                                                  150,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                  )
                                  .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                  ),
                            );
                          },
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
    );
  }
}

// Improved bottom navigation with state preservation
class ImprovedBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ImprovedBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.show_chart_rounded, 'label': 'Progress'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
      {'icon': Icons.notifications_rounded, 'label': 'Notifications'},
    ];

    return Container(
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
            color: Colors.pink.shade200.withAlpha(128),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items:
            items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return BottomNavigationBarItem(
                icon: _buildNavIcon(index, item['icon'] as IconData),
                label: item['label'] as String,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon) {
    return Container(
          decoration:
              selectedIndex == index
                  ? BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(15),
                  )
                  : null,
          padding: const EdgeInsets.all(6),
          child: Icon(icon),
        )
        .animate(target: selectedIndex == index ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
        );
  }
}

// Optimized particle system using AnimationController
class OptimizedParticleSystem extends StatefulWidget {
  final Widget child;

  const OptimizedParticleSystem({super.key, required this.child});

  @override
  State<OptimizedParticleSystem> createState() =>
      _OptimizedParticleSystemState();
}

class _OptimizedParticleSystemState extends State<OptimizedParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<MagicalParticle> _particles = List.generate(
    15,
    (_) => MagicalParticle(),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Update particles without rebuilding the entire widget
            for (var particle in _particles) {
              particle.update();
            }
            return CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 70),
              painter: ParticlesPainter(_particles),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

// Magical particle class for bottom navigation animation
class MagicalParticle {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speed;

  MagicalParticle() {
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

    // Use withAlpha instead of withOpacity for better performance
    final alpha = (Random().nextDouble() * 0.7 + 0.3) * 255;
    color = colors[Random().nextInt(colors.length)].withAlpha(alpha.toInt());

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
class ParticlesPainter extends CustomPainter {
  final List<MagicalParticle> particles;

  ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
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
