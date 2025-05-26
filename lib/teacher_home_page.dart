import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'Features/teacher_class_details_page.dart';

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
    String teacher,
    String topic,
    String date,
    String time,
    String link,
    int reminderMinutes,
  ) {
    // Generate a unique class ID
    String classId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a batch to perform multiple operations
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Create the main class document
    DocumentReference classRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(classId);
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
      'reminderMinutes': reminderMinutes,
    });

    // Debug the selected students
    debugPrint(
      "Selected students for class $classId: ${selectedStudents.length}",
    );
    for (var student in selectedStudents) {
      debugPrint(
        "Student: ${student['name']}, ID: ${student['id']}, Email: ${student['email']}",
      );
    }

    // Add student enrollments
    for (var student in selectedStudents) {
      // Ensure we have a valid student ID
      String studentId = student['id'] ?? '';
      if (studentId.isEmpty) {
        debugPrint("⚠️ Warning: Empty student ID for ${student['name']}");
        continue;
      }

      // Create enrollment with combined ID for uniqueness
      // We'll use the Firestore document ID which should be the Firebase UID
      DocumentReference studentEnrollmentRef = FirebaseFirestore.instance
          .collection('class_enrollments')
          .doc('${classId}_$studentId');

      // Store both the studentId and email to make lookups easier
      batch.set(studentEnrollmentRef, {
        'classId': classId,
        'studentId': studentId, // This should be the Firebase UID
        'studentName': student['name'] ?? 'Student',
        'studentEmail': student['email'] ?? '',
        'hasJoined': false,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': studentId, // Explicitly store the UID for clarity
      });

      // Create notification document for each student - use the same studentId for consistency
      DocumentReference notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      batch.set(notificationRef, {
        'userId': studentId, // Use the same ID consistently
        'title': 'New Class Scheduled',
        'message':
            'You have a new class on $topic with $teacher scheduled for $date at $time.',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'class',
        'classId': classId,
      });
    }

    batch
        .commit()
        .then((value) async {
          debugPrint("Class and enrollments saved to Firestore successfully");
          DateTime classDateTime = DateFormat(
            'yyyy-MM-dd hh:mm a',
          ).parse('$date $time');
          if (classDateTime.isAfter(DateTime.now())) {
            // Show custom success SnackBar instead of toast
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Class scheduled successfully!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$topic on $date at $time",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }

            await LocalNotificationService.showNotification(
              id: classId.hashCode, // Unique ID for each notification
              title: "Class Scheduled",
              body:
                  "You scheduled a class on '$topic' for $date at $time with ${selectedStudents.length} students!",
            );

            // Schedule a notification for 15 minutes before class starts
            final reminderDuration = Duration(minutes: reminderMinutes);
            DateTime reminderTime = classDateTime.subtract(reminderDuration);

            if (reminderTime.isAfter(DateTime.now())) {
              await LocalNotificationService.scheduleNotification(
                id: ("${classId}_reminder").hashCode,
                title: "Class Reminder",
                body:
                    "Class: $topic, Time: $time ($reminderMinutes mins before)",
                scheduledTime: reminderTime,
              );
              debugPrint(
                "Scheduled $reminderMinutes-min reminder for teacher for class $classId at $reminderTime",
              );
            } else {
              debugPrint(
                "$reminderMinutes-min reminder for teacher for class $classId is in the past, not scheduling.",
              );
            }
          }

          // Clear selected students after scheduling
          setState(() {
            selectedStudents = [];
          });
        })
        .catchError((error) {
          debugPrint("Error scheduling class: $error");
          // Show error with SnackBar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text("Error scheduling class: $error")),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
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
    final TextEditingController reminderMinutesController =
        TextEditingController(text: '15');

    // Create a local copy of selectedStudents to avoid direct manipulation
    List<Map<String, dynamic>> localSelectedStudents = [...selectedStudents];

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    Future<void> selectDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.green.shade700,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
            ),
            child: child!,
          );
        },
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
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.green.shade700,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
            ),
            child: child!,
          );
        },
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Text(
                              "Schedule New Class",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Teacher Name Field
                          Text(
                            "Teacher Name",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: teacherController,
                            decoration: InputDecoration(
                              hintText: "Enter teacher name",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter teacher name"
                                        : null,
                          ),
                          SizedBox(height: 16),

                          // Topic Field
                          Text(
                            "Topic",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: topicController,
                            decoration: InputDecoration(
                              hintText: "Enter class topic",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter a topic"
                                        : null,
                          ),
                          SizedBox(height: 16),

                          // Date Field
                          Text(
                            "Date",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: dateController,
                            decoration: InputDecoration(
                              hintText: "Select date",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  color: Colors.green.shade700,
                                ),
                                onPressed: selectDate,
                              ),
                            ),
                            readOnly: true,
                            onTap: selectDate,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please select a date"
                                        : null,
                          ),
                          SizedBox(height: 16),

                          // Time Field
                          Text(
                            "Time",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: timeController,
                            decoration: InputDecoration(
                              hintText: "Select time",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.access_time,
                                  color: Colors.green.shade700,
                                ),
                                onPressed: selectTime,
                              ),
                            ),
                            readOnly: true,
                            onTap: selectTime,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please select a time"
                                        : null,
                          ),
                          SizedBox(height: 16),

                          // Class Link Field
                          Text(
                            "Class Link",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: linkController,
                            decoration: InputDecoration(
                              hintText: "Enter class link",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter class link"
                                        : null,
                          ),
                          SizedBox(height: 16),

                          // Reminder Minutes Field
                          Text(
                            "Reminder Before Class (minutes)",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: reminderMinutesController,
                            decoration: InputDecoration(
                              hintText: "e.g., 10, 15, 30",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade700,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter reminder minutes";
                              }
                              final int? minutes = int.tryParse(value);
                              if (minutes == null || minutes < 0) {
                                return "Please enter a valid positive number";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Selected Students
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.green.shade700),
                              SizedBox(width: 8),
                              Text(
                                "Selected Students: ${localSelectedStudents.length}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Empty Students Warning
                          if (localSelectedStudents.isEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade800,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Please select students from the Students tab",
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Student List
                          if (localSelectedStudents.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade50,
                              ),
                              constraints: BoxConstraints(maxHeight: 180),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.symmetric(vertical: 8),
                                itemCount: localSelectedStudents.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          localSelectedStudents[index]['avatar'] !=
                                                      null &&
                                                  localSelectedStudents[index]['avatar']
                                                      .isNotEmpty
                                              ? AssetImage(
                                                localSelectedStudents[index]['avatar'],
                                              )
                                              : null,
                                      backgroundColor: Colors.green.shade100,
                                      child:
                                          localSelectedStudents[index]['avatar'] ==
                                                      null ||
                                                  localSelectedStudents[index]['avatar']
                                                      .isEmpty
                                              ? Text(
                                                localSelectedStudents[index]['name'][0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                ),
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      localSelectedStudents[index]['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      localSelectedStudents[index]['email'] ??
                                          '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onPressed: () {
                                        setDialogState(() {
                                          localSelectedStudents.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: 24),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cancel Button
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Schedule Button
                              ElevatedButton(
                                onPressed:
                                    localSelectedStudents.isEmpty
                                        ? null
                                        : () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            // Update the main selectedStudents list with our local copy
                                            setState(() {
                                              selectedStudents = [
                                                ...localSelectedStudents,
                                              ];
                                            });

                                            final int reminderMinutes =
                                                int.tryParse(
                                                  reminderMinutesController
                                                      .text,
                                                ) ??
                                                15;

                                            addClassToFirebase(
                                              teacherController.text,
                                              topicController.text,
                                              dateController.text,
                                              timeController.text,
                                              linkController.text,
                                              reminderMinutes,
                                            );
                                            Navigator.pop(context);
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Schedule Class",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Upcoming Classes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  StreamBuilder(
                    stream:
                        FirebaseFirestore.instance
                            .collection('classes')
                            .where('user', isEqualTo: email)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      var allClasses = snapshot.data!.docs;

                      // Get the current date and time
                      DateTime now = DateTime.now();

                      // Separate upcoming and past classes without deleting
                      var upcomingClasses = <QueryDocumentSnapshot>[];
                      var pastClasses = <QueryDocumentSnapshot>[];

                      for (var classDoc in allClasses) {
                        try {
                          String dateStr =
                              classDoc['date']; // Format: yyyy-MM-dd
                          String timeStr =
                              classDoc['time']; // Format: HH:mm AM/PM

                          // Convert date and time to DateTime object
                          DateTime classDateTime = DateFormat(
                            'yyyy-MM-dd hh:mm a',
                          ).parse('$dateStr $timeStr');

                          // Sort into upcoming or past without deleting
                          if (classDateTime.isAfter(now)) {
                            upcomingClasses.add(classDoc);
                          } else {
                            pastClasses.add(classDoc);
                          }
                        } catch (e) {
                          debugPrint("Error parsing date/time: $e");
                          // Keep classes with invalid dates in upcoming for review
                          upcomingClasses.add(classDoc);
                        }
                      }

                      if (upcomingClasses.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No upcoming classes scheduled!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Click the "Schedule Class" button to create one.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: upcomingClasses.length,
                          itemBuilder: (context, index) {
                            var classData = upcomingClasses[index];
                            return ClassCard(
                              title: classData['topic'],
                              teacher: classData['teacher'],
                              date: classData['date'],
                              time: classData['time'],
                              link: classData['link'],
                              studentCount: classData['studentCount'] ?? 0,
                              classId: classData.id,
                              onCancel:
                                  () =>
                                      FirebaseFirestore.instance
                                          .collection('classes')
                                          .doc(classData.id)
                                          .delete(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Past Classes Section
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Past Classes",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder(
                    stream:
                        FirebaseFirestore.instance
                            .collection('classes')
                            .where('user', isEqualTo: email)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      var allClasses = snapshot.data!.docs;

                      // Get the current date and time
                      DateTime now = DateTime.now();

                      // Filter to get only past classes
                      var pastClasses = <QueryDocumentSnapshot>[];

                      for (var classDoc in allClasses) {
                        try {
                          String dateStr =
                              classDoc['date']; // Format: yyyy-MM-dd
                          String timeStr =
                              classDoc['time']; // Format: HH:mm AM/PM

                          // Convert date and time to DateTime object
                          DateTime classDateTime = DateFormat(
                            'yyyy-MM-dd hh:mm a',
                          ).parse('$dateStr $timeStr');

                          // Only include past classes
                          if (classDateTime.isBefore(now)) {
                            pastClasses.add(classDoc);
                          }
                        } catch (e) {
                          debugPrint(
                            "Error parsing date/time for past class: $e",
                          );
                        }
                      }

                      if (pastClasses.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No past classes available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: pastClasses.length,
                          itemBuilder: (context, index) {
                            var classData = pastClasses[index];
                            return PastClassCard(
                              title: classData['topic'],
                              teacher: classData['teacher'],
                              date: classData['date'],
                              time: classData['time'],
                              link: classData['link'],
                              studentCount: classData['studentCount'] ?? 0,
                              classId: classData.id,
                              onDelete:
                                  () =>
                                      FirebaseFirestore.instance
                                          .collection('classes')
                                          .doc(classData.id)
                                          .delete(),
                            );
                          },
                        ),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

            // Filter users - standardize on 'Kid' but keep backward compatibility
            final usersToShow =
                snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userType = data['userType']?.toString() ?? '';

                  // Primary check for standardized 'Kid' type
                  if (userType == 'Kid') return true;

                  // Fallback for backward compatibility with older user types
                  final lowerUserType = userType.toLowerCase();
                  return lowerUserType.contains('kid') ||
                      lowerUserType.contains('student') ||
                      lowerUserType == 'child';
                }).toList();

            if (usersToShow.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Found ${snapshot.data!.docs.length} users, but none are students",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        bool isSelected = selectedStudents.any(
                          (s) => s['id'] == studentId,
                        );

                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isSelected
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
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(studentEmail),
                            secondary: CircleAvatar(
                              backgroundImage:
                                  studentAvatar.isNotEmpty
                                      ? AssetImage(studentAvatar)
                                      : null,
                              radius: 25,
                              child:
                                  studentAvatar.isEmpty
                                      ? Text(studentName[0])
                                      : null,
                            ),
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
    try {
      String linkToLaunch = link.trim();

      // If URL doesn't have a scheme, add https://
      if (!linkToLaunch.startsWith('http://') &&
          !linkToLaunch.startsWith('https://') &&
          !linkToLaunch.startsWith('zoom://') &&
          !linkToLaunch.contains('://')) {
        linkToLaunch = 'https://$linkToLaunch';
      }

      final Uri url = Uri.parse(linkToLaunch);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Fluttertoast.showToast(
          msg:
              "Could not open the class link. No app available to handle this link.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      Fluttertoast.showToast(
        msg: "Error opening class link: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with green accent
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and student count
                  Row(
                    children: [
                      // Green vertical bar
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Student count badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "$studentCount students",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Teacher
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                      SizedBox(width: 8),
                      Text(
                        teacher,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Date and time (HORIZONTALLY DISPLAYED)
                  Row(
                    children: [
                      // Date
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 6),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12),

                      // Time
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            SizedBox(width: 6),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
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

          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Join Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _launchURL,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Join Class",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Students button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ClassEnrollmentsPage(
                                classId: classId,
                                title: title,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Students",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Details button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  TeacherClassDetailsPage(classId: classId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Delete button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text("Cancel Class"),
                              ],
                            ),
                            content: Text(
                              "Are you sure you want to cancel this class?",
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  "No",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onCancel();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Yes, Cancel"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    splashRadius: 20,
                    tooltip: "Cancel Class",
                    iconSize: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
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
        stream:
            FirebaseFirestore.instance
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

class PastClassCard extends StatelessWidget {
  final String title, teacher, date, time, link, classId;
  final int studentCount;
  final VoidCallback onDelete;

  const PastClassCard({
    super.key,
    required this.title,
    required this.teacher,
    required this.date,
    required this.time,
    required this.link,
    required this.classId,
    required this.onDelete,
    this.studentCount = 0,
  });

  void _launchURL() async {
    try {
      String linkToLaunch = link.trim();

      // If URL doesn't have a scheme, add https://
      if (!linkToLaunch.startsWith('http://') &&
          !linkToLaunch.startsWith('https://') &&
          !linkToLaunch.startsWith('zoom://') &&
          !linkToLaunch.contains('://')) {
        linkToLaunch = 'https://$linkToLaunch';
      }

      final Uri url = Uri.parse(linkToLaunch);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Fluttertoast.showToast(
          msg:
              "Could not open the class link. No app available to handle this link.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      Fluttertoast.showToast(
        msg: "Error opening class link: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with grey accent to show it's a past class
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and student count
                  Row(
                    children: [
                      // Grey vertical bar for past class
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Student count badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "$studentCount students",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Teacher
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                      SizedBox(width: 8),
                      Text(
                        teacher,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Past indicator, date and time
                  Row(
                    children: [
                      // Past indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Colors.blueGrey.shade700,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Past",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12),

                      // Date
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 6),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12),

                      // Time
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 6),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
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

          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Recording Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _launchURL,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Recording",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Students button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ClassEnrollmentsPage(
                                classId: classId,
                                title: title,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Students",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Details button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  TeacherClassDetailsPage(classId: classId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Delete button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text("Delete Class"),
                              ],
                            ),
                            content: Text(
                              "Are you sure you want to delete this past class?",
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  "No",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onDelete();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Yes, Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    splashRadius: 20,
                    tooltip: "Delete Class",
                    iconSize: 20,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
