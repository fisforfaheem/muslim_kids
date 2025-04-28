import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherHomePage extends StatefulWidget {
  final String email;
  const TeacherHomePage({super.key, required this.email});

  @override
  TeacherHomePageState createState() => TeacherHomePageState();
}

class TeacherHomePageState extends State<TeacherHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> selectedStudents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void addClassToFirebase(
      String teacher, String topic, String date, String time, String link) {
    // Generate a unique class ID
    String classId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a batch to perform multiple operations
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Create the main class document
    DocumentReference classRef =
        FirebaseFirestore.instance.collection('classes').doc(classId);
    batch.set(classRef, {
      'id': classId,
      'user': widget.email,
      'teacher': teacher,
      'topic': topic,
      'date': date,
      'time': time,
      'link': link,
      'timestamp': FieldValue.serverTimestamp(),
      'studentCount': selectedStudents.length,
    });

    // Add student enrollments
    for (var student in selectedStudents) {
      DocumentReference studentEnrollmentRef = FirebaseFirestore.instance
          .collection('class_enrollments')
          .doc('${classId}_${student['id']}');

      batch.set(studentEnrollmentRef, {
        'classId': classId,
        'studentId': student['id'],
        'studentName': student['name'],
        'studentEmail': student['email'],
        'hasJoined': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create notification document for each student
      DocumentReference notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      batch.set(notificationRef, {
        'userId': student['id'],
        'title': 'New Class Scheduled',
        'message':
            'You have a new class on $topic with $teacher scheduled for $date at $time.',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'class',
        'classId': classId
      });
    }

    batch.commit().then((value) async {
      DateTime classDateTime =
          DateFormat('yyyy-MM-dd hh:mm a').parse('$date $time');
      if (classDateTime.isAfter(DateTime.now())) {
        Fluttertoast.showToast(
          msg: "Class scheduled successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 18.0,
          toastLength: Toast.LENGTH_SHORT,
        );

        await LocalNotificationService.showNotification(
          id: classId.hashCode, // Unique ID for each notification
          title: "Class Scheduled",
          body:
              "You scheduled a class on '$topic' for $date at $time with ${selectedStudents.length} students!",
        );

        // Schedule a notification for 15 minutes before class starts
        Duration timeUntilClass = classDateTime.difference(DateTime.now());
        if (timeUntilClass.inMinutes > 15) {
          Duration notifyBefore = timeUntilClass - const Duration(minutes: 15);
          await LocalNotificationService.scheduleNotification(
            id: ("${classId}_reminder").hashCode,
            title: "Class Starting Soon",
            body: "Your class on '$topic' starts in 15 minutes!",
            scheduledTime: DateTime.now().add(notifyBefore),
          );
        }
      }

      // Clear selected students after scheduling
      setState(() {
        selectedStudents = [];
      });
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "Error scheduling class: $error",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 18.0,
        toastLength: Toast.LENGTH_SHORT,
      );
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Show toast message
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "As-Salaam-Alaikum",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: "Classes"),
            Tab(icon: Icon(Icons.people), text: "Students"),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Classes Tab
          ClassesTab(
            email: widget.email,
            onScheduleClass: showScheduleClassDialog,
          ),

          // Students Tab
          StudentsTab(
            onStudentSelected: (student, isSelected) {
              setState(() {
                if (isSelected) {
                  if (!selectedStudents.any((s) => s['id'] == student['id'])) {
                    selectedStudents.add(student);
                  }
                } else {
                  selectedStudents.removeWhere((s) => s['id'] == student['id']);
                }
              });
            },
            selectedStudents: selectedStudents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showScheduleClassDialog,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void showScheduleClassDialog() {
    final TextEditingController teacherController = TextEditingController();
    final TextEditingController topicController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController linkController = TextEditingController();

    Future<void> selectDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null && mounted) {
        setState(() {
          dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        });
      }
    }

    Future<void> selectTime() async {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          timeController.text = pickedTime.format(context);
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text("Schedule New Class",
              style: TextStyle(
                  color: Colors.green[700], fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: teacherController,
                    decoration: InputDecoration(labelText: "Teacher Name")),
                TextField(
                    controller: topicController,
                    decoration: InputDecoration(labelText: "Topic")),
                TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                        labelText: "Date",
                        suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: selectDate)),
                    readOnly: true),
                TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                        labelText: "Time",
                        suffixIcon: IconButton(
                            icon: Icon(Icons.access_time),
                            onPressed: selectTime)),
                    readOnly: true),
                TextField(
                    controller: linkController,
                    decoration: InputDecoration(labelText: "Class Link")),
                SizedBox(height: 10),
                Text(
                  "Selected Students: ${selectedStudents.length}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selectedStudents.isEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 5),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "Please select students from the Students tab",
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                if (selectedStudents.isNotEmpty)
                  Container(
                    height: 100,
                    margin: EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: selectedStudents.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundImage: selectedStudents[index]
                                            ['avatar'] !=
                                        null &&
                                    selectedStudents[index]['avatar'].isNotEmpty
                                ? AssetImage(selectedStudents[index]['avatar'])
                                : null,
                            child: selectedStudents[index]['avatar'] == null ||
                                    selectedStudents[index]['avatar'].isEmpty
                                ? Text(selectedStudents[index]['name'][0])
                                : null,
                          ),
                          title: Text(selectedStudents[index]['name']),
                          trailing: IconButton(
                            icon: Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                selectedStudents.removeAt(index);
                              });
                              // Rebuild the dialog
                              Navigator.pop(context);
                              showScheduleClassDialog();
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
            ElevatedButton(
                onPressed: selectedStudents.isEmpty
                    ? null // Disable button if no students selected
                    : () {
                        addClassToFirebase(
                            teacherController.text,
                            topicController.text,
                            dateController.text,
                            timeController.text,
                            linkController.text);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text("Submit", style: TextStyle(color: Colors.white))),
          ],
        );
      },
    );
  }
}

class ClassesTab extends StatelessWidget {
  final String email;
  final VoidCallback onScheduleClass;

  const ClassesTab({
    super.key,
    required this.email,
    required this.onScheduleClass,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage('assets/teacher.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: onScheduleClass,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "Schedule Class",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming Classes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .where('user', isEqualTo: email)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var classes = snapshot.data!.docs;

                      // Get the current date and time
                      DateTime now = DateTime.now();

                      // Filter out expired classes
                      for (var classDoc in classes) {
                        try {
                          String dateStr =
                              classDoc['date']; // Format: yyyy-MM-dd
                          String timeStr =
                              classDoc['time']; // Format: HH:mm AM/PM

                          // Convert date and time to DateTime object
                          DateTime classDateTime =
                              DateFormat('yyyy-MM-dd hh:mm a')
                                  .parse('$dateStr $timeStr');

                          // If class time has passed, delete from Firebase
                          if (classDateTime.isBefore(now)) {
                            FirebaseFirestore.instance
                                .collection('classes')
                                .doc(classDoc.id)
                                .delete();
                          }
                        } catch (e) {
                          debugPrint("Error parsing date/time: $e");
                        }
                      }

                      // Remove deleted classes from the list
                      classes.removeWhere((classDoc) {
                        try {
                          String dateStr = classDoc['date'];
                          String timeStr = classDoc['time'];
                          DateTime classDateTime =
                              DateFormat('yyyy-MM-dd hh:mm a')
                                  .parse('$dateStr $timeStr');
                          return classDateTime.isBefore(now);
                        } catch (e) {
                          return false;
                        }
                      });

                      if (classes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No class scheduled yet! If you want to schedule Islamic lesson click "Schedule Class" button.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          var classData = classes[index];
                          return ClassCard(
                            title: classData['topic'],
                            teacher: classData['teacher'],
                            date: classData['date'],
                            time: classData['time'],
                            link: classData['link'],
                            studentCount: classData['studentCount'] ?? 0,
                            classId: classData.id,
                            onCancel: () => FirebaseFirestore.instance
                                .collection('classes')
                                .doc(classData.id)
                                .delete(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentsTab extends StatelessWidget {
  final Function(Map<String, dynamic>, bool) onStudentSelected;
  final List<Map<String, dynamic>> selectedStudents;

  const StudentsTab({
    super.key,
    required this.onStudentSelected,
    required this.selectedStudents,
  });

  @override
  Widget build(BuildContext context) {
    // Debug the Firestore connection first
    return FutureBuilder<void>(
      future: _checkFirestoreConnection(),
      builder: (context, connectionSnapshot) {
        if (connectionSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Now query all users and filter in the app instead of relying on Firestore query
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  "Unable to fetch user data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            // Debug information
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "No users found in the database",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _createSampleStudents(context),
                      child: Text("Create Sample Students"),
                    ),
                  ],
                ),
              );
            }

            // Filter users (could be 'Kid', 'kid', 'student', etc.)
            final usersToShow = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final userType = data['userType']?.toString().toLowerCase() ?? '';

              // Accept multiple possible user types for students
              return userType.contains('kid') ||
                  userType.contains('student') ||
                  userType == 'child';
            }).toList();

            if (usersToShow.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Found ${snapshot.data!.docs.length} users, but none are students",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "User types found: ${_getUserTypesDebugString(snapshot.data!.docs)}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _createSampleStudents(context),
                      child: Text("Create Sample Students"),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Students (${usersToShow.length})",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        "Selected: ${selectedStudents.length}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: usersToShow.length,
                      itemBuilder: (context, index) {
                        var studentData =
                            usersToShow[index].data() as Map<String, dynamic>;
                        String studentId = usersToShow[index].id;
                        String studentName = studentData['name'] ?? 'Student';
                        String studentEmail = studentData['email'] ?? '';
                        String studentAvatar = studentData['avatar'] ?? '';

                        // Check if student is already selected
                        bool isSelected =
                            selectedStudents.any((s) => s['id'] == studentId);

                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.transparent,
                              width: isSelected ? 2 : 0,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              // Create a map with all needed student data
                              Map<String, dynamic> student = {
                                'id': studentId,
                                'name': studentName,
                                'email': studentEmail,
                                'avatar': studentAvatar,
                              };
                              onStudentSelected(student, value ?? false);
                            },
                            title: Text(
                              studentName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(studentEmail),
                            secondary: CircleAvatar(
                              backgroundImage: studentAvatar.isNotEmpty
                                  ? AssetImage(studentAvatar)
                                  : null,
                              radius: 25,
                              child: studentAvatar.isEmpty
                                  ? Text(studentName[0])
                                  : null,
                            ),
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Check if we can connect to Firestore at all
  Future<void> _checkFirestoreConnection() async {
    try {
      await FirebaseFirestore.instance.collection('users').limit(1).get();
    } catch (e) {
      debugPrint("🔴 Error connecting to Firestore: $e");
    }
  }

  // Create sample student profiles for testing
  Future<void> _createSampleStudents(BuildContext context) async {
    try {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Creating sample students..."),
              ],
            ),
          );
        },
      );

      // Create a batch for multiple operations
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Sample student data
      final sampleStudents = [
        {
          'name': 'Ahmed Khan',
          'email': 'ahmed@example.com',
          'userType': 'Kid',
          'avatar': 'assets/avatar1.jpg',
        },
        {
          'name': 'Fatima Ali',
          'email': 'fatima@example.com',
          'userType': 'Kid',
          'avatar': 'assets/avatar2.jpg',
        },
        {
          'name': 'Zainab Hassan',
          'email': 'zainab@example.com',
          'userType': 'Kid',
          'avatar': 'assets/avatar3.jpg',
        },
      ];

      // Add each student to the batch
      for (var student in sampleStudents) {
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('users').doc();
        batch.set(docRef, student);
      }

      // Commit the batch
      await batch.commit();

      // Close the loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Created ${sampleStudents.length} sample students"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating sample students: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get debug info about user types
  String _getUserTypesDebugString(List<QueryDocumentSnapshot> docs) {
    final userTypes = <String>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userType = data['userType']?.toString() ?? 'null';
      userTypes.add(userType);
    }

    return userTypes.join(', ');
  }
}

class ClassCard extends StatelessWidget {
  final String title, teacher, date, time, link, classId;
  final int studentCount;
  final VoidCallback onCancel;

  const ClassCard({
    super.key,
    required this.title,
    required this.teacher,
    required this.date,
    required this.time,
    required this.link,
    required this.onCancel,
    required this.classId,
    this.studentCount = 0,
  });

  void _launchURL() async {
    final Uri url = Uri.parse(link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue[800]),
                    SizedBox(width: 4),
                    Text(
                      "$studentCount students",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            teacher,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(width: 10),
              Icon(Icons.access_time, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _launchURL,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                icon: Icon(Icons.video_call, color: Colors.white, size: 16),
                label: Text("Join Class",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassEnrollmentsPage(classId: classId, title: title),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: Icon(Icons.people, color: Colors.white, size: 16),
                label: Text("Students",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              ElevatedButton.icon(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: Icon(Icons.cancel, color: Colors.white, size: 16),
                label: Text("Cancel",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClassEnrollmentsPage extends StatelessWidget {
  final String classId;
  final String title;

  const ClassEnrollmentsPage({
    super.key,
    required this.classId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students - $title"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('class_enrollments')
            .where('classId', isEqualTo: classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No students enrolled in this class.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var enrollment =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              bool hasJoined = enrollment['hasJoined'] ?? false;

              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasJoined ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    child: Text(enrollment['studentName'][0]),
                  ),
                  title: Text(
                    enrollment['studentName'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(enrollment['studentEmail']),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasJoined ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasJoined ? "Joined" : "Not joined",
                      style: TextStyle(
                        color: hasJoined ? Colors.green[700] : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
