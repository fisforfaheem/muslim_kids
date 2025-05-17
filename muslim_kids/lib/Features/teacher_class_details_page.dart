import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherClassDetailsPage extends StatefulWidget {
  final String classId;

  const TeacherClassDetailsPage({super.key, required this.classId});

  @override
  _TeacherClassDetailsPageState createState() =>
      _TeacherClassDetailsPageState();
}

class _TeacherClassDetailsPageState extends State<TeacherClassDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic> classData = {};
  List<Map<String, dynamic>> enrolledStudents = [];
  List<Map<String, dynamic>> notificationStatus = [];
  TextEditingController linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  Future<void> _loadClassData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load class data
      final classDoc =
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .get();

      if (!classDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Class not found')));
          Navigator.pop(context);
        }
        return;
      }

      // Set class data
      final data = classDoc.data() as Map<String, dynamic>;
      setState(() {
        classData = {'id': classDoc.id, ...data};
        linkController.text = data['meetingLink'] ?? '';
      });

      // Get enrolled students
      final enrollmentsSnapshot =
          await FirebaseFirestore.instance
              .collection('class_enrollments')
              .where('classId', isEqualTo: widget.classId)
              .get();

      List<Map<String, dynamic>> students = [];
      Map<String, bool> processedStudentIds = {};

      for (var enrollment in enrollmentsSnapshot.docs) {
        final enrollmentData = enrollment.data();
        final studentId = enrollmentData['studentId'];

        // Skip if we've already processed this student
        if (processedStudentIds[studentId] == true) {
          continue;
        }

        processedStudentIds[studentId] = true;

        // Get student data - directly access by ID instead of query
        try {
          // Try to get the user document directly by ID first
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentId)
                  .get();

          Map<String, dynamic> studentData = {
            'id': studentId,
            'name': 'Unknown Student',
            'email': 'unknown@example.com',
            'hasNotification': false,
          };

          if (userDoc.exists) {
            // Document exists, use its data
            final userData = userDoc.data() as Map<String, dynamic>;
            studentData['name'] = userData['name'] ?? 'Unknown';
            studentData['email'] = userData['email'] ?? 'unknown@example.com';
          } else {
            // If not found by direct ID, try a fallback query
            final fallbackQuery =
                await FirebaseFirestore.instance
                    .collection('users')
                    .where('uid', isEqualTo: studentId)
                    .limit(1)
                    .get();

            if (fallbackQuery.docs.isNotEmpty) {
              final userData = fallbackQuery.docs.first.data();
              studentData['name'] = userData['name'] ?? 'Unknown';
              studentData['email'] = userData['email'] ?? 'unknown@example.com';
            } else {
              debugPrint(
                'Could not find user data in Firestore for $studentId',
              );
            }
          }

          // Check if student has notification for this class
          final notificationsSnapshot =
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: studentId)
                  .where('classId', isEqualTo: widget.classId)
                  .get();

          studentData['hasNotification'] =
              notificationsSnapshot.docs.isNotEmpty;

          students.add(studentData);
        } catch (e) {
          debugPrint('Error getting student data: $e');
        }
      }

      setState(() {
        enrolledStudents = students;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading class data: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading class data: $e')));
      }
    }
  }

  Future<void> _updateMeetingLink() async {
    if (linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid meeting link')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
            'meetingLink': linkController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting link updated successfully')),
        );
      }

      // Optionally send notifications to students about updated link
      for (var student in enrolledStudents) {
        try {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': student['id'],
            'title': 'Class Link Updated',
            'message':
                'The link for ${classData['title']} has been updated. Please check the class details.',
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'class_update',
            'classId': widget.classId,
          });
        } catch (e) {
          debugPrint('Error sending notification to ${student['name']}: $e');
        }
      }

      setState(() {
        classData['meetingLink'] = linkController.text;
      });
    } catch (e) {
      debugPrint('Error updating meeting link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating meeting link: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Send manual notifications to all enrolled students
  Future<void> _resendNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;

      for (var student in enrolledStudents) {
        try {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': student['id'],
            'title': 'Class Reminder',
            'message':
                'Reminder: You have class "${classData['title']}" scheduled at ${_formatClassTime(classData['date'])}',
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'class_reminder',
            'classId': widget.classId,
          });
          successCount++;
        } catch (e) {
          debugPrint('Error sending notification to ${student['name']}: $e');
          failureCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent $successCount notifications, $failureCount failed',
            ),
          ),
        );
      }

      // Refresh data to show updated notification status
      _loadClassData();
    } catch (e) {
      debugPrint('Error sending notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notifications: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatClassTime(dynamic date) {
    if (date == null) return 'Unknown time';

    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    }

    return 'Unknown time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classData['title'] ?? 'Class Details')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class details card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classData['title'] ?? 'No Title',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Time: ${_formatClassTime(classData['date'])}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subject: ${classData['subject'] ?? 'Not specified'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Description: ${classData['description'] ?? 'No description'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: linkController,
                              decoration: InputDecoration(
                                labelText: 'Meeting Link',
                                hintText: 'Enter Zoom/Google Meet link here',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.save),
                                  onPressed: _updateMeetingLink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.notifications),
                                    label: Text('Resend Notifications'),
                                    onPressed: _resendNotifications,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enrolled students section
                    Text(
                      'Enrolled Students (${enrolledStudents.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    if (enrolledStudents.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No students enrolled in this class yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: enrolledStudents.length,
                        itemBuilder: (context, index) {
                          final student = enrolledStudents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(student['name'].substring(0, 1)),
                              ),
                              title: Text(student['name']),
                              subtitle: Text(student['email']),
                              trailing: Icon(
                                student['hasNotification']
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color:
                                    student['hasNotification']
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    linkController.dispose();
    super.dispose();
  }
}
