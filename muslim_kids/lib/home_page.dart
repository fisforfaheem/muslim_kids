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

class HomePage extends StatefulWidget {
  final String userType;
  final String email;
  const HomePage({super.key, required this.userType,required this.email});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (widget.userType == 'Kid' && FirebaseAuth.instance.currentUser?.email==widget.email)
          ? KidHomePage(email:widget.email)  // Show Kid's homepage if userType is 'Kid'
          : TeacherHomePage(email:widget.email), // Show Teacher's homepage if userType is 'Teacher'
    );
  }
}

class KidHomePage extends StatefulWidget {
   final String email;
  const KidHomePage({super.key, required this.email});

  @override
  KidHomePageState createState() => KidHomePageState();
}

class KidHomePageState extends State<KidHomePage> {
  int _selectedIndex = 0; // Track selected index for the bottom navigation
  final List<Widget> _pages = [
    const KidHomePageContent(),
    const ProgressPage(),
    const SettingsPage(),
    //const NotificationPage(),
  ];

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
            selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              //BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
            ],
          ),
        ),
      ),
    );
  }
}

class KidHomePageContent extends StatelessWidget {
  const KidHomePageContent({super.key});

  final List<String> carouselImages = const [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
  ];

  final List<Map<String, dynamic>> tiles = const [
    {'title': 'Prayer Alarm', 'image': 'assets/prayer_time.jpg', 'color': Colors.deepOrangeAccent, 'page': PrayerAlarmPage()},
    {'title': 'Quizzes', 'image': 'assets/quizzes.jpg', 'color': Colors.orange, 'page': QuizzesPage()},
    {'title': 'Videos', 'image': 'assets/videos.jpg', 'color': Colors.deepPurpleAccent, 'page': VideosPage()},
    {'title': 'Live Classes', 'image': 'assets/live_classes.jpg', 'color': Colors.blue, 'page': LiveClassesPage()},
    {'title': 'Islamic Calendar', 'image': 'assets/islamic_calendar.jpg', 'color': Colors.green, 'page': IslamicCalendarPage()},
    {'title': 'Prayer Tracker', 'image': 'assets/prayer_tracker.jpg', 'color': Colors.pink, 'page': PrayerTrackerPage()},
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
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius:30,
                  backgroundImage: AssetImage('assets/avatar2.jpg'),
                ),
                const SizedBox(width: 10),
                Text(
                  'As-Salaam-Alaikum',
                  style: GoogleFonts.kanit(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
                          MaterialPageRoute(builder: (context) => tiles[index]['page']),
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


