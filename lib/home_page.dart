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
import 'package:muslim_kids/widgets/loading_skeleton.dart';
import 'package:muslim_kids/services/user_data_service.dart';
import 'package:muslim_kids/mixins/safe_state_mixin.dart';

import 'package:muslim_kids/widgets/navigation_helper.dart';
import 'teacher_home_page.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

class _KidHomePageContentState extends State<KidHomePageContent>
    with SafeStateMixin {
  final UserDataService _userDataService = UserDataService();
  UserData? _userData;
  bool _isLoading = true;
  late StreamSubscription<UserData?> _userDataSubscription;
  late StreamSubscription<bool> _loadingSubscription;
  late StreamSubscription<String?> _errorSubscription;

  @override
  void initState() {
    super.initState();

    // Use initial values if provided for immediate display
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _userData = UserData(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        name: widget.initialName!,
        email: '',
        avatar: widget.initialAvatar ?? 'assets/avatar2.jpg',
        userType: 'Kid',
      );
      _isLoading = false;
    }

    _initializeUserDataService();

    // Show tutorial for first-time users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationHelper.showAppTutorial(context);
    });
  }

  /// Initialize user data service and set up listeners
  void _initializeUserDataService() {
    // Listen to user data changes
    _userDataSubscription = _userDataService.userDataStream.listen((userData) {
      safeSetState(() {
        _userData = userData;
      });
    });

    // Listen to loading state changes
    _loadingSubscription = _userDataService.loadingStream.listen((loading) {
      safeSetState(() {
        _isLoading = loading;
      });
    });

    // Listen to error state changes
    _errorSubscription = _userDataService.errorStream.listen((error) {
      if (error != null) {
        showErrorMessage(error);
      }
    });

    // Initialize the service
    _userDataService.initialize();
  }

  @override
  void dispose() {
    _userDataSubscription.cancel();
    _loadingSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
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

  final List<String> carouselImages = const [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
    'assets/77.jpg',
    'assets/22.jpg',
    'assets/55.jpg',
    'assets/112233.jpeg',
    'assets/3332323.jpeg',
    'assets/233232323.jpeg',
    'assets/dasdasdasdas.jpeg',
    'assets/dfsd.jpeg',
    'assets/asdasd.jpeg',
    'assets/333.jpeg',
  ];

  List<Map<String, dynamic>> get tiles => [
    {
      'title': 'Prayer Alarm',
      'image': 'assets/prayer_time.jpg',
      'color': Colors.deepOrangeAccent, // Back to fun orange
      'page': const PrayerAlarmPage(),
    },
    {
      'title': 'Quizzes',
      'image': 'assets/quizzes.jpg',
      'color': Colors.orange, // Back to bright orange
      'page': const QuizzesPage(),
    },
    {
      'title': 'Videos',
      'image': 'assets/videos.jpg',
      'color': Colors.deepPurpleAccent, // Back to fun purple
      'page': const VideosPage(),
    },
    {
      'title': 'Live Classes',
      'image': 'assets/live_classes.jpg',
      'color': Colors.blue, // Back to bright blue
      'page': const LiveClassesPage(),
    },
    {
      'title': 'Islamic Calendar',
      'image': 'assets/islamic_calendar.jpg',
      'color': Colors.green, // Back to bright green
      'page': const IslamicCalendarPage(),
    },
    {
      'title': 'Prayer Tracker',
      'image': 'assets/prayer_tracker.jpg',
      'color': Colors.pink, // Back to bright pink
      'page': const PrayerTrackerPage(),
    },

    // Debug tile - only visible in development
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        255,
        244,
        143,
      ), // Back to fun yellow
      extendBody: true,
      appBar: IslamicHeader(
        avatarPath: _userData?.avatar,
        userName: _userData?.name ?? 'User',
        isLoading: _isLoading,
        onLogoutPressed: _logout,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 244, 143), // Fun yellow
              Color.fromARGB(255, 255, 230, 100), // Bright yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Fun colorful background decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(60), // Fun orange
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -40,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50), // Fun green
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 200,
                left: -30,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.pink.withAlpha(40), // Fun pink
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Column(
                  children: [
                    // Welcome banner with fun colors
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withAlpha(180),
                            Colors.yellow.shade50.withAlpha(150),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withAlpha(60),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.orange.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withAlpha(100),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                                  "Welcome to Muslim Kids!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purple.shade700,
                                    letterSpacing: 0.3,
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
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withAlpha(100),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Carousel with fun styling
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        height: 240,
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 240.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 0.85,
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
                                    horizontal: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withAlpha(80),
                                        blurRadius: 15.0,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: Image.asset(
                                      image,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: 240.0,
                                      cacheWidth: 800,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    // Improved grid with bright colors
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child:
                            _isLoading && _userData == null
                                ? GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 1.1,
                                      ),
                                  itemCount: 6,
                                  itemBuilder: (context, index) {
                                    return const GridTileLoadingSkeleton();
                                  },
                                )
                                : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 1.1,
                                      ),
                                  itemCount: tiles.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    tiles[index]['page'],
                                          ),
                                        );
                                      },
                                      child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  (tiles[index]['color']
                                                          as Color)
                                                      .withAlpha(220),
                                                  tiles[index]['color']
                                                      as Color,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (tiles[index]['color']
                                                          as Color)
                                                      .withAlpha(120),
                                                  blurRadius: 15,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Colors.white.withAlpha(
                                                  100,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withAlpha(200),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.white
                                                              .withAlpha(150),
                                                          blurRadius: 8,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Image.asset(
                                                      tiles[index]['image'],
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    tiles[index]['title'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      letterSpacing: 0.3,
                                                      height: 1.3,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 2),
                                                          blurRadius: 4,
                                                          color: Color.fromARGB(
                                                            180,
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

// Colorful bottom navigation that kids love
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade300,
            Colors.pink.shade200,
            Colors.purple.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(100),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withAlpha(100), width: 2),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withAlpha(180),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
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
                    color: Colors.white.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ],
                  )
                  : null,
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        )
        .animate(target: selectedIndex == index ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 200),
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
