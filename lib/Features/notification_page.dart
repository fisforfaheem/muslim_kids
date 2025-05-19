import 'package:flutter/material.dart';
import 'package:muslim_kids/local_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_kids/Features/live_classes_page.dart';

class NotificationPage extends StatefulWidget {
  final bool fromBottomNav;

  const NotificationPage({super.key, this.fromBottomNav = false});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // First get the user document to get the actual ID used in notifications
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (!userDoc.exists) {
        debugPrint('User document not found for ${currentUser.uid}');
        setState(() {
          isLoading = false;
        });
        return;
      }

      String studentId = userDoc.id; // Firebase Auth UID
      debugPrint('Looking for notifications for studentId: $studentId');

      // Query notifications collection for current user - use consistent ID approach
      final QuerySnapshot notificationsSnapshot =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: studentId)
              .orderBy('timestamp', descending: true)
              .get();

      // Convert to list of maps
      final List<Map<String, dynamic>> loadedNotifications =
          notificationsSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();

      debugPrint('Found ${loadedNotifications.length} notifications');

      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });

      // Check notification delivery system
      _checkNotificationDelivery();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Check if notification system is working and fix if needed
  Future<void> _checkNotificationDelivery() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if local notifications are working
      bool notificationsEnabled =
          await LocalNotificationService.checkPermissions();
      if (!notificationsEnabled) {
        debugPrint(
          'Local notifications are not enabled. Requesting permissions...',
        );
        // Re-initialize notification service to request permissions
        await LocalNotificationService.initialize();
      }

      // Check if we have any notifications in Firestore
      if (notifications.isEmpty) {
        // Find classes the user is enrolled in
        final QuerySnapshot enrollmentsSnapshot =
            await FirebaseFirestore.instance
                .collection('class_enrollments')
                .where('studentId', isEqualTo: currentUser.uid)
                .limit(5)
                .get();

        if (enrollmentsSnapshot.docs.isNotEmpty) {
          debugPrint(
            'User has enrollments but no notifications. Creating test notification...',
          );

          // Create a test notification for the user
          DocumentReference notificationRef =
              FirebaseFirestore.instance.collection('notifications').doc();
          await notificationRef.set({
            'userId': currentUser.uid,
            'title': 'Welcome to Muslim Kids App',
            'message': 'Your notification system is now set up correctly.',
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'system',
          });

          debugPrint(
            'Test notification created with ID: ${notificationRef.id}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking notification delivery: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      // Update local state
      setState(() {
        final index = notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read
    await _markAsRead(notification['id']);

    if (!mounted) return;

    // Navigate based on notification type
    final String notificationType = notification['type'] ?? '';

    switch (notificationType) {
      case 'class':
      case 'class_reminder':
      case 'class_update':
        // For all class-related notifications, go to live classes page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiveClassesPage()),
        );
        break;

      case 'system':
        // For system notifications, just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification['message'] ?? 'System notification'),
            backgroundColor: Colors.blue,
          ),
        );
        break;

      default:
        // For unknown notification types, show a message
        debugPrint('Unknown notification type: $notificationType');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification received'),
            backgroundColor: Colors.grey,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 244, 143),
      appBar: AppBar(
        backgroundColor: Colors.pink[200],
        automaticallyImplyLeading: false, // Disable automatic back button
        leading:
            widget.fromBottomNav
                ? null // Don't show back button if opened from bottom nav
                : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
        title: Text(
          'Notifications',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.kanit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When your teacher schedules a class,\nyou\'ll see it here!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final bool isRead = notification['read'] ?? false;
                  final DateTime timestamp =
                      notification['timestamp'] != null
                          ? (notification['timestamp'] as Timestamp).toDate()
                          : DateTime.now();
                  final String timeAgo = _getTimeAgo(timestamp);

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isRead ? Colors.transparent : Colors.blue,
                        width: isRead ? 0 : 2,
                      ),
                    ),
                    elevation: isRead ? 1 : 3,
                    child: InkWell(
                      onTap: () => _handleNotificationTap(notification),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: EdgeInsets.only(right: 8),
                                  ),
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? 'Notification',
                                    style: GoogleFonts.kanit(
                                      fontSize: 18,
                                      fontWeight:
                                          isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              notification['message'] ?? '',
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            if (notification['type'] == 'class')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: Icon(Icons.video_call),
                                  label: Text('View Class'),
                                  onPressed:
                                      () =>
                                          _handleNotificationTap(notification),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
