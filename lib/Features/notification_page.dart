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

        // User has enrollments but no notifications - this is normal
        // No need to create test notifications
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

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'No Title';
    final message = notification['message'] ?? 'No Message';
    final timestamp = notification['timestamp'] as Timestamp?;
    final bool isRead = notification['read'] ?? false;
    final String notificationType = notification['type'] ?? '';

    IconData iconData;
    Color iconColor;

    switch (notificationType) {
      case 'class':
      case 'class_reminder':
      case 'class_update':
        iconData = Icons.class_;
        iconColor = Colors.blue.shade700;
        break;
      case 'prayer_alarm':
        iconData = Icons.alarm;
        iconColor = Colors.orange.shade700;
        break;
      case 'system':
        iconData = Icons.info_outline;
        iconColor = Colors.green.shade700;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey.shade700;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isRead ? Colors.grey.shade300 : _getBorderColor(notificationType),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(iconData, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 17,
            color: isRead ? Colors.grey.shade700 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: isRead ? Colors.grey.shade600 : Colors.black54,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: () => _handleNotificationTap(notification),
        // Removed any explicit trailing widget like a "Details" button
      ),
    );
  }

  Color _getBorderColor(String type) {
    switch (type) {
      case 'class':
      case 'class_reminder':
      case 'class_update':
        return Colors.blue.shade300;
      case 'prayer_alarm':
        return Colors.orange.shade300;
      case 'system':
        return Colors.green.shade300;
      default:
        return Colors.purple.shade200; // A default vibrant color
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        245,
        240,
        247,
      ), // Lighter purple-ish background
      appBar: AppBar(
        backgroundColor: Colors.purple.shade300, // Theme color
        elevation: 1,
        automaticallyImplyLeading: !widget.fromBottomNav,
        leading:
            widget.fromBottomNav
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
        title: Text(
          'Notifications',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
          ),
          IconButton(
            // Added for clearing all notifications
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _confirmClearAllNotifications,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              )
              : notifications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 100,
                      color: Colors.purple.shade200,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Notifications Yet',
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'Important updates and class reminders will appear here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                color: Colors.purple.shade400,
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 80,
                  ), // Added bottom padding for FAB
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notifications[index]);
                  },
                ),
              ),
      floatingActionButton:
          notifications.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _confirmClearReadNotifications,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Read'),
                backgroundColor: Colors.purple.shade400,
              )
              : null,
    );
  }

  // Placeholder for new methods to clear notifications
  Future<void> _confirmClearReadNotifications() async {
    // Implementation to confirm and clear read notifications
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Read Notifications?'),
          content: const Text(
            'Are you sure you want to delete all read notifications? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _clearReadNotifications();
    }
  }

  Future<void> _clearReadNotifications() async {
    // Actual logic to delete read notifications from Firestore and update UI
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    List<String> readNotificationIds = [];

    for (var notification in notifications) {
      if (notification['read'] == true) {
        readNotificationIds.add(notification['id']);
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification['id']);
        batch.delete(docRef);
      }
    }

    if (readNotificationIds.isNotEmpty) {
      try {
        await batch.commit();
        // Update UI
        setState(() {
          notifications.removeWhere(
            (n) => readNotificationIds.contains(n['id']),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Read notifications cleared.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing read notifications: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing notifications: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No read notifications to clear.')),
      );
    }
  }

  Future<void> _confirmClearAllNotifications() async {
    // Implementation to confirm and clear ALL notifications
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications?'),
          content: const Text(
            'Are you sure you want to delete ALL notifications? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _clearAllNotifications();
    }
  }

  Future<void> _clearAllNotifications() async {
    // Actual logic to delete ALL notifications for the user from Firestore and update UI
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    List<String> allNotificationIds =
        notifications.map((n) => n['id'] as String).toList();

    if (allNotificationIds.isNotEmpty) {
      for (String id in allNotificationIds) {
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(id);
        batch.delete(docRef);
      }
      try {
        await batch.commit();
        // Update UI
        setState(() {
          notifications.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error clearing all notifications: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing all notifications: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notifications to clear.')),
      );
    }
  }
}
