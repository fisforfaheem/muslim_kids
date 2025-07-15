import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class AppHelpGuide extends StatefulWidget {
  const AppHelpGuide({super.key});

  @override
  State<AppHelpGuide> createState() => _AppHelpGuideState();
}

class _AppHelpGuideState extends State<AppHelpGuide>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;
  int _currentPage = 0;

  final List<AppFeature> _features = [
    AppFeature(
      title: 'Welcome to MuslimKids',
      description:
          'Your Islamic learning companion designed to help kids grow in faith through interactive features and engaging content.',
      icon: Icons.mosque,
      color: Colors.purple,
      illustration: 'assets/child.jpg',
      points: [
        'Learn Islamic teachings',
        'Track your prayers',
        'Take fun quizzes',
        'Join live classes',
      ],
    ),
    AppFeature(
      title: 'Quranic Quizzes',
      description:
          'Test your knowledge with interactive quizzes and earn points as you learn about the Quran and Islamic teachings.',
      icon: Icons.quiz,
      color: Colors.blue,
      illustration: 'assets/quizzes.jpg',
      points: [
        'Multiple choice questions',
        'Earn points for correct answers',
        'Track your progress',
        'Unlock achievements',
      ],
    ),
    AppFeature(
      title: 'Prayer Tracker',
      description:
          'Keep track of your daily prayers and build a streak. Never miss a prayer with our easy-to-use tracker.',
      icon: Icons.check_circle,
      color: Colors.green,
      illustration: 'assets/prayer_tracker.jpg',
      points: [
        'Track all 5 daily prayers',
        'Build prayer streaks',
        'Get completion rewards',
        'View your progress',
      ],
    ),
    AppFeature(
      title: 'Prayer Alarms',
      description:
          'Get notified for prayer times with beautiful alerts and never miss a prayer again.',
      icon: Icons.access_time,
      color: Colors.orange,
      illustration: 'assets/prayer_time.jpg',
      points: [
        'Location-based prayer times',
        'Customizable notifications',
        'Beautiful prayer reminders',
        'Automatic updates',
      ],
    ),
    AppFeature(
      title: 'Islamic Calendar',
      description:
          'Explore important Islamic events and holidays throughout the year with detailed information.',
      icon: Icons.calendar_today,
      color: Colors.teal,
      illustration: 'assets/islamic_calendar.jpg',
      points: [
        'View Islamic events',
        'Hijri calendar dates',
        'Event descriptions',
        'Monthly overview',
      ],
    ),
    AppFeature(
      title: 'Live Classes',
      description:
          'Join live Islamic classes with qualified teachers and learn together with other students.',
      icon: Icons.video_call,
      color: Colors.red,
      illustration: 'assets/live_classes.jpg',
      points: [
        'Interactive live sessions',
        'Qualified teachers',
        'Real-time learning',
        'Class notifications',
      ],
    ),
    AppFeature(
      title: 'Educational Videos',
      description:
          'Watch engaging Islamic educational videos designed specifically for children.',
      icon: Icons.play_circle_filled,
      color: Colors.indigo,
      illustration: 'assets/videos.jpg',
      points: [
        'Age-appropriate content',
        'High-quality videos',
        'Various topics',
        'Safe viewing experience',
      ],
    ),
    AppFeature(
      title: 'Progress & Achievements',
      description:
          'Track your learning journey and unlock badges as you complete various activities.',
      icon: Icons.emoji_events,
      color: Colors.amber,
      illustration: 'assets/99.jpg',
      points: [
        'View your statistics',
        'Unlock achievements',
        'Earn badges',
        'Track streaks',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _floatingAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    HapticFeedback.lightImpact();
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturePage(_features[index]);
                  },
                ),
              ),
              // Navigation Controls
              _buildNavigationControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'App Guide',
            style: GoogleFonts.kanit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage(AppFeature feature) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  // Feature Illustration
                  Expanded(flex: 1, child: _buildFeatureIllustration(feature)),
                  const SizedBox(height: 10),
                  // Feature Content
                  Expanded(flex: 2, child: _buildFeatureContent(feature)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIllustration(AppFeature feature) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(feature.illustration),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          feature.color.withOpacity(0.3),
                          BlendMode.overlay,
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          feature.color.withOpacity(0.2),
                          feature.color.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(feature.icon, size: 60, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureContent(AppFeature feature) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            feature.title,
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: feature.color,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            feature.description,
            style: GoogleFonts.kanit(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Feature Points
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children:
                  feature.points.map((point) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: feature.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_features.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 15),
          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Previous',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              // Next/Done Button
              ElevatedButton.icon(
                onPressed:
                    _currentPage < _features.length - 1
                        ? _nextPage
                        : () => Navigator.of(context).pop(),
                icon: Icon(
                  _currentPage < _features.length - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                  color: Colors.white,
                ),
                label: Text(
                  _currentPage < _features.length - 1 ? 'Next' : 'Done',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String illustration;
  final List<String> points;

  AppFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustration,
    required this.points,
  });
}
