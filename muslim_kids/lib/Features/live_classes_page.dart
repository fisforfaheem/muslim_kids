import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LiveClassesPage extends StatelessWidget {
  const LiveClassesPage({super.key});

  void _launchURL(BuildContext context, String link, String classId,
      String studentId) async {
    if (link.isNotEmpty && Uri.tryParse(link)?.hasAbsolutePath == true) {
      final Uri url = Uri.parse(link);

      // Update the join status
      await FirebaseFirestore.instance
          .collection('class_enrollments')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: studentId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({'hasJoined': true});
        }
      });

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch the class link')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid class link')),
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
        body: Center(
          child: Text('Please log in to view your classes'),
        ),
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
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('class_enrollments')
            .where('studentId', isEqualTo: currentUser.uid)
            .get(),
        builder: (context, enrollmentSnapshot) {
          if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
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
                    errorBuilder: (context, error, stackTrace) => Icon(
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
                        Icon(Icons.lightbulb,
                            color: Colors.orange[800], size: 30),
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
          List<String> enrolledClassIds = enrollmentSnapshot.data!.docs
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['classId'] as String)
              .toList();

          // Fetch class details for enrolled classes
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where(FieldPath.documentId, whereIn: enrolledClassIds)
                .snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
                return Center(child: Text("No class details available"));
              }

              var classes = classSnapshot.data!.docs;

              // Filter out classes that have already happened
              DateTime now = DateTime.now();
              classes = classes.where((classDoc) {
                try {
                  String dateStr = classDoc['date']; // Format: yyyy-MM-dd
                  String timeStr = classDoc['time']; // Format: HH:mm AM/PM

                  // Convert date and time to DateTime object
                  DateTime classDateTime = DateFormat('yyyy-MM-dd hh:mm a')
                      .parse('$dateStr $timeStr');

                  // Keep classes that haven't happened yet
                  return classDateTime.isAfter(now);
                } catch (e) {
                  debugPrint("Error parsing date/time: $e");
                  return true; // Keep classes with unparseable dates by default
                }
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Expanded(
                      child: classes.isEmpty
                          ? Center(
                              child: Text(
                                "No upcoming classes. All your scheduled classes have finished.",
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: classes.length,
                              itemBuilder: (context, index) {
                                var classData = classes[index].data()
                                    as Map<String, dynamic>;
                                String classId = classes[index].id;

                                // Calculate time remaining until class
                                DateTime classDateTime =
                                    DateFormat('yyyy-MM-dd hh:mm a').parse(
                                        '${classData['date']} ${classData['time']}');
                                Duration timeUntil =
                                    classDateTime.difference(now);
                                String timeRemaining = '';

                                if (timeUntil.inDays > 0) {
                                  timeRemaining =
                                      '${timeUntil.inDays} day(s) left';
                                } else if (timeUntil.inHours > 0) {
                                  timeRemaining =
                                      '${timeUntil.inHours} hour(s) left';
                                } else if (timeUntil.inMinutes > 0) {
                                  timeRemaining =
                                      '${timeUntil.inMinutes} minute(s) left';
                                } else {
                                  timeRemaining = 'Starting now!';
                                }

                                return Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: timeUntil.inMinutes < 15
                                              ? Colors.red
                                              : Colors.blue,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                classData['topic'],
                                                style: GoogleFonts.kanit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.person,
                                                    size: 18,
                                                    color: Colors.purple),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Teacher: ${classData['teacher']}",
                                                  style: GoogleFonts.kanit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 18,
                                                    color: Colors.green),
                                                SizedBox(width: 8),
                                                Text(
                                                  classData['date'],
                                                  style: GoogleFonts.kanit(
                                                      fontSize: 14),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(Icons.access_time,
                                                    size: 18,
                                                    color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text(
                                                  classData['time'],
                                                  style: GoogleFonts.kanit(
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    timeUntil.inMinutes < 30
                                                        ? () => _launchURL(
                                                            context,
                                                            classData['link'],
                                                            classId,
                                                            currentUser.uid)
                                                        : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  disabledBackgroundColor:
                                                      Colors.grey,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.video_call,
                                                  color: Colors.white,
                                                ),
                                                label: Text(
                                                  timeUntil.inMinutes < 30
                                                      ? "Join Class"
                                                      : "Class starts in ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m",
                                                  style: GoogleFonts.kanit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}
