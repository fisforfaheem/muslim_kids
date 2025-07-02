import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Add clipboard functionality
import 'package:muslim_kids/local_notification_service.dart'; // Added import

class LiveClassesPage extends StatelessWidget {
  const LiveClassesPage({super.key});

  // Track scheduled notifications to prevent duplicates
  static final Set<String> _scheduledNotifications = <String>{};

  void _launchURL(
    BuildContext context,
    String link,
    String classId,
    String studentId,
  ) async {
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No class link provided by teacher')),
      );
      return;
    }

    // Ensure link has proper scheme
    String processedLink = link;
    if (!link.startsWith('http://') &&
        !link.startsWith('https://') &&
        !link.startsWith('whatsapp://') &&
        !link.startsWith('tel:') &&
        !link.startsWith('sms:') &&
        !link.startsWith('mailto:') &&
        !link.startsWith('zoom:')) {
      // Add https if no protocol is specified
      processedLink = 'https://$link';
    }

    // Try to parse the URL
    final Uri? uri = Uri.tryParse(processedLink);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid class link format')));
      return;
    }

    // Update the join status in Firestore with improved error handling
    try {
      // Use the consistent document ID format: classId_studentId
      final enrollmentDocId = '${classId}_$studentId';
      final docRef = FirebaseFirestore.instance
          .collection('class_enrollments')
          .doc(enrollmentDocId);

      debugPrint(
        "Attempting to update join status for enrollment: $enrollmentDocId",
      );

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists with the expected ID format
        await docRef.update({
          'hasJoined': true,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ Successfully updated join status using document ID");
      } else {
        debugPrint(
          "⚠️ Enrollment document not found with ID: $enrollmentDocId",
        );

        // Fallback: Search for enrollment using query
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('class_enrollments')
                .where('classId', isEqualTo: classId)
                .where('studentId', isEqualTo: studentId)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'hasJoined': true,
            'joinedAt': FieldValue.serverTimestamp(),
          });
          debugPrint("✅ Successfully updated join status using query fallback");
        } else {
          debugPrint(
            "❌ No enrollment found for student $studentId in class $classId",
          );

          // Show warning to user but don't prevent class joining
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: Enrollment not found, but opening class link anyway',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error updating join status: $e");
      // Show error but continue with class joining
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Could not update join status'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Log the link we're trying to launch
    debugPrint("Attempting to launch URL: $uri");

    try {
      // Launch URL with appropriate mode
      bool launched = false;

      // WhatsApp links need special handling
      if (uri.toString().contains('whatsapp')) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Zoom links
      else if (uri.toString().contains('zoom')) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // All other URLs
      else {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      }

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open the class link. Please try again or contact your teacher.',
              ),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy Link',
                onPressed: () {
                  // Copy link to clipboard
                  Clipboard.setData(ClipboardData(text: processedLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied to clipboard'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        // Show a success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening class link...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Live Classes'),
          backgroundColor: Colors.pink[200],
        ),
        body: Center(child: Text('Please log in to view your classes')),
      );
    }

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Live Classes',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // First get the user document to get the proper studentId
        future:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(
              child: Text(
                "User profile not found. Please contact support.",
                style: GoogleFonts.kanit(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Get the student ID from the user document
          String studentId = userSnapshot.data!.id;
          String studentName =
              (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ??
              'Student';

          debugPrint("Looking for classes for student ID: $studentId");

          // Use the Firebase Auth UID consistently for enrollments
          return FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('class_enrollments')
                    .where('studentId', isEqualTo: studentId)
                    .get(),
            builder: (context, enrollmentSnapshot) {
              if (enrollmentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!enrollmentSnapshot.hasData ||
                  enrollmentSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/no_classes.png',
                        height: 120,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No classes scheduled yet!",
                        style: GoogleFonts.kanit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Your teacher hasn't scheduled any Islamic lessons for you yet.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange),
                        ),
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.orange[800],
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "When a teacher schedules a class, you'll receive a notification!",
                                style: GoogleFonts.kanit(
                                  fontSize: 14,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Get all class IDs the student is enrolled in
              List<String> enrolledClassIds =
                  enrollmentSnapshot.data!.docs
                      .map(
                        (doc) =>
                            (doc.data() as Map<String, dynamic>)['classId']
                                as String,
                      )
                      .toList();

              debugPrint(
                "Found ${enrolledClassIds.length} enrolled classes for student: $studentName",
              );

              // Display message if no enrolled classes found
              if (enrolledClassIds.isEmpty) {
                return Center(
                  child: Text(
                    "No classes found. Please contact your teacher.",
                    style: GoogleFonts.kanit(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Fetch class details for enrolled classes
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('classes')
                        .where(FieldPath.documentId, whereIn: enrolledClassIds)
                        .snapshots(),
                builder: (context, classSnapshot) {
                  if (classSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!classSnapshot.hasData ||
                      classSnapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No live class scheduled!",
                        style: GoogleFonts.kanit(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  var allClasses = classSnapshot.data!.docs;
                  debugPrint("Retrieved ${allClasses.length} class details");

                  // Sort classes by date (newest first)
                  allClasses.sort((a, b) {
                    try {
                      String dateA = a['date']; // Format: yyyy-MM-dd
                      String timeA = a['time']; // Format: HH:mm AM/PM
                      String dateB = b['date']; // Format: yyyy-MM-dd
                      String timeB = b['time']; // Format: HH:mm AM/PM

                      DateTime dateTimeA = DateFormat(
                        'yyyy-MM-dd hh:mm a',
                      ).parse('$dateA $timeA');
                      DateTime dateTimeB = DateFormat(
                        'yyyy-MM-dd hh:mm a',
                      ).parse('$dateB $timeB');

                      return dateTimeB.compareTo(dateTimeA); // Descending order
                    } catch (e) {
                      return 0; // Keep original order if there's an error
                    }
                  });

                  // Filter out classes based on current time
                  DateTime now = DateTime.now();
                  var upcomingClasses =
                      allClasses.where((classDoc) {
                        try {
                          String dateStr =
                              classDoc['date']; // Format: yyyy-MM-dd
                          String timeStr =
                              classDoc['time']; // Format: HH:mm AM/PM

                          // Convert date and time to DateTime object
                          DateTime classDateTime = DateFormat(
                            'yyyy-MM-dd hh:mm a',
                          ).parse('$dateStr $timeStr');

                          // Keep classes that haven't happened yet
                          return classDateTime.isAfter(now);
                        } catch (e) {
                          debugPrint("Error parsing date/time: $e");
                          return true; // Keep classes with unparseable dates by default
                        }
                      }).toList();

                  // Schedule reminders for upcoming classes on the kid's device (only once per class)

                  for (var classDoc in upcomingClasses) {
                    try {
                      var classData = classDoc.data() as Map<String, dynamic>;
                      String classId = classDoc.id;
                      String topic =
                          classData['title'] ??
                          classData['topic'] ??
                          'Unknown Topic'; // Use new field name
                      String dateStr = classData['date'];
                      String timeStr = classData['time'];

                      // Create unique key for this notification
                      String notificationKey =
                          "${classId}_${studentId}_reminder";

                      // Skip if already scheduled
                      if (_scheduledNotifications.contains(notificationKey)) {
                        continue;
                      }

                      // Get reminderMinutes from classData, default to 15 if not present or invalid
                      int reminderMinutes = 15; // Default value
                      if (classData.containsKey('reminderMinutes')) {
                        final dynamic rawReminderMinutes =
                            classData['reminderMinutes'];
                        if (rawReminderMinutes is int) {
                          reminderMinutes =
                              rawReminderMinutes > 0 ? rawReminderMinutes : 15;
                        } else if (rawReminderMinutes is String) {
                          final parsedMinutes = int.tryParse(
                            rawReminderMinutes,
                          );
                          reminderMinutes =
                              (parsedMinutes != null && parsedMinutes > 0)
                                  ? parsedMinutes
                                  : 15;
                        }
                      }

                      DateTime classDateTime = DateFormat(
                        'yyyy-MM-dd hh:mm a',
                      ).parse('$dateStr $timeStr');
                      DateTime reminderTime = classDateTime.subtract(
                        Duration(
                          minutes: reminderMinutes,
                        ), // Use fetched reminderMinutes
                      );

                      if (reminderTime.isAfter(DateTime.now())) {
                        // Using a distinct ID for student-side reminders
                        int notificationId = notificationKey.hashCode;
                        String notificationTitle = "Class Reminder";
                        String notificationBody =
                            "Class: $topic, Time: $timeStr ($reminderMinutes mins before)"; // Updated body

                        // Schedule without awaiting to prevent UI blocking
                        LocalNotificationService.scheduleNotification(
                              id: notificationId,
                              title: notificationTitle,
                              body: notificationBody,
                              scheduledTime: reminderTime,
                            )
                            .then((_) {
                              _scheduledNotifications.add(
                                notificationKey,
                              ); // Mark as scheduled
                              debugPrint(
                                "Student Reminder: Scheduled $reminderMinutes-min reminder for class $classId ($topic) at $reminderTime. ID: $notificationId",
                              );
                            })
                            .catchError((e) {
                              debugPrint(
                                "Student Reminder: Error during scheduling for class $classId ($topic): $e",
                              );
                            });
                      }
                    } catch (e) {
                      debugPrint(
                        "Student Reminder: Error processing reminder for class ${classDoc.id}: $e",
                      );
                    }
                  }

                  // Filter past classes (classes that have already happened)
                  var pastClasses =
                      allClasses.where((classDoc) {
                        try {
                          String dateStr =
                              classDoc['date']; // Format: yyyy-MM-dd
                          String timeStr =
                              classDoc['time']; // Format: HH:mm AM/PM

                          // Convert date and time to DateTime object
                          DateTime classDateTime = DateFormat(
                            'yyyy-MM-dd hh:mm a',
                          ).parse('$dateStr $timeStr');

                          // Keep classes that have already happened
                          return classDateTime.isBefore(now);
                        } catch (e) {
                          debugPrint("Error parsing date/time: $e");
                          return false; // Exclude classes with unparseable dates for past classes
                        }
                      }).toList();

                  debugPrint(
                    "${upcomingClasses.length} upcoming classes and ${pastClasses.length} past classes",
                  );

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upcoming Classes Section
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: Colors.white, size: 30),
                              SizedBox(width: 10),
                              Text(
                                "Upcoming Classes",
                                style: GoogleFonts.kanit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Main scrollable content area with both sections
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Upcoming Classes List or Empty State
                                upcomingClasses.isEmpty
                                    ? Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.event_busy,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              "No upcoming classes",
                                              style: GoogleFonts.kanit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "All your scheduled classes have finished.",
                                              style: GoogleFonts.kanit(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    : Column(
                                      children:
                                          upcomingClasses.map((classDoc) {
                                            var classData =
                                                classDoc.data()
                                                    as Map<String, dynamic>;
                                            String classId = classDoc.id;

                                            // Calculate time remaining until class
                                            DateTime classDateTime = DateFormat(
                                              'yyyy-MM-dd hh:mm a',
                                            ).parse(
                                              '${classData['date']} ${classData['time']}',
                                            );
                                            Duration timeUntil = classDateTime
                                                .difference(now);
                                            String timeRemaining = '';

                                            if (timeUntil.inDays > 0) {
                                              timeRemaining =
                                                  '${timeUntil.inDays} day(s) left';
                                            } else if (timeUntil.inHours > 0) {
                                              timeRemaining =
                                                  '${timeUntil.inHours} hour(s) left';
                                            } else if (timeUntil.inMinutes >
                                                0) {
                                              timeRemaining =
                                                  '${timeUntil.inMinutes} minute(s) left';
                                            } else {
                                              timeRemaining = 'Starting now!';
                                            }

                                            return UpcomingClassCard(
                                              classData: classData,
                                              classId: classId,
                                              timeUntil: timeUntil,
                                              timeRemaining: timeRemaining,
                                              studentId: studentId,
                                              onJoinClass: _launchURL,
                                            );
                                          }).toList(),
                                    ),

                                SizedBox(height: 24),

                                // Past Classes Section Header
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Class History",
                                        style: GoogleFonts.kanit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Past Classes List or Empty State
                                pastClasses.isEmpty
                                    ? Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.history_toggle_off,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              "No class history",
                                              style: GoogleFonts.kanit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "Your completed classes will appear here",
                                              style: GoogleFonts.kanit(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    : Column(
                                      children:
                                          pastClasses.take(5).map((classDoc) {
                                            var classData =
                                                classDoc.data()
                                                    as Map<String, dynamic>;
                                            String classId = classDoc.id;

                                            return PastClassCard(
                                              classData: classData,
                                              classId: classId,
                                              studentId: studentId,
                                              onJoinClass: _launchURL,
                                            );
                                          }).toList(),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Extract UpcomingClassCard to separate widget
class UpcomingClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String classId;
  final Duration timeUntil;
  final String timeRemaining;
  final String studentId;
  final Function(BuildContext, String, String, String) onJoinClass;

  const UpcomingClassCard({
    super.key,
    required this.classData,
    required this.classId,
    required this.timeUntil,
    required this.timeRemaining,
    required this.studentId,
    required this.onJoinClass,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: timeUntil.inMinutes < 15 ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classData['title'] ??
                        classData['topic'] ??
                        'Class', // Support both field names
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeRemaining,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Teacher: ${classData['teacher']}',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Text(
                      classData['date'],
                      style: GoogleFonts.kanit(fontSize: 14),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.orange[700]),
                    SizedBox(width: 8),
                    Text(
                      classData['time'],
                      style: GoogleFonts.kanit(fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      () => onJoinClass(
                        context,
                        classData['meetingLink'] ??
                            classData['link'] ??
                            '', // Support both field names
                        classId,
                        studentId,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        timeUntil.inMinutes < 15 ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.video_call),
                  label: Text(
                    timeUntil.inMinutes < 15 ? 'Join Class Now!' : 'Join Class',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

// Extract PastClassCard to separate widget
class PastClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String classId;
  final String studentId;
  final Function(BuildContext, String, String, String) onJoinClass;

  const PastClassCard({
    super.key,
    required this.classData,
    required this.classId,
    required this.studentId,
    required this.onJoinClass,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classData['title'] ??
                        classData['topic'] ??
                        'Class', // Support both field names
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Completed',
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Teacher: ${classData['teacher']}',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      classData['date'],
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                    SizedBox(width: 8),
                    Text(
                      classData['time'],
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
