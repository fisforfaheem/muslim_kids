import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muslim_kids/Features/islamic_calendar_page.dart';
import 'package:muslim_kids/Features/live_classes_page.dart';
//import 'package:muslim_kids/Features/notification_page.dart';
import 'package:muslim_kids/Features/prayer_alarm_page.dart';
import 'package:muslim_kids/Features/prayer_tracker_page.dart';
import 'package:muslim_kids/Features/progress_page.dart';
import 'package:muslim_kids/Features/quizzes_page.dart';
import 'package:muslim_kids/Features/settings_page.dart';
import 'package:muslim_kids/Features/videos_page.dart';
import 'teacher_home_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  final String userType;
  final String email;
  final String name;
  final String avatar;

  const HomePage(
      {super.key,
      required this.userType,
      required this.email,
      this.name = '',
      this.avatar = 'assets/avatar2.jpg'});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (widget.userType == 'Kid' &&
              FirebaseAuth.instance.currentUser?.email == widget.email)
          ? KidHomePage(
              email: widget.email,
              name: widget.name,
              avatar: widget.avatar) // Show Kid's homepage if userType is 'Kid'
          : TeacherHomePage(
              email: widget
                  .email), // Show Teacher's homepage if userType is 'Teacher'
    );
  }
}

class KidHomePage extends StatefulWidget {
  final String email;
  final String name;
  final String avatar;

  const KidHomePage(
      {super.key,
      required this.email,
      this.name = '',
      this.avatar = 'assets/avatar2.jpg'});

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
          initialName: widget.name, initialAvatar: widget.avatar),
      const ProgressPage(),
      const SettingsPage(),
      //const NotificationPage(),
    ];
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
      body: _pages[_selectedIndex], // Switch pages based on the selected index
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.pink[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle:
                TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: 'Progress'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: 'Settings'),
              //BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
            ],
          ),
        ),
      ),
    );
  }
}

class KidHomePageContent extends StatefulWidget {
  final String? initialName;
  final String? initialAvatar;

  const KidHomePageContent({
    super.key,
    this.initialName,
    this.initialAvatar,
  });

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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
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
      print('Error loading user data: $e');
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
      'page': PrayerAlarmPage()
    },
    {
      'title': 'Quizzes',
      'image': 'assets/quizzes.jpg',
      'color': Colors.orange,
      'page': QuizzesPage()
    },
    {
      'title': 'Videos',
      'image': 'assets/videos.jpg',
      'color': Colors.deepPurpleAccent,
      'page': VideosPage()
    },
    {
      'title': 'Live Classes',
      'image': 'assets/live_classes.jpg',
      'color': Colors.blue,
      'page': LiveClassesPage()
    },
    {
      'title': 'Islamic Calendar',
      'image': 'assets/islamic_calendar.jpg',
      'color': Colors.green,
      'page': IslamicCalendarPage()
    },
    {
      'title': 'Prayer Tracker',
      'image': 'assets/prayer_tracker.jpg',
      'color': Colors.pink,
      'page': PrayerTrackerPage()
    },
  ];

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
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      AssetImage(userAvatar ?? 'assets/avatar2.jpg'),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  isLoading ? 'Loading...' : 'Welcome, ${userName ?? 'User'}!',
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.black87),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
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
                  items: carouselImages.map((image) {
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
                              builder: (context) => tiles[index]['page']),
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
