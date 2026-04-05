const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// Cloud Function to send notifications when a new class is created
exports.sendClassNotification = onDocumentCreated(
    "classes/{classId}",
    async (event) => {
      const classData = event.data.data();
      const classId = event.params.classId;

      console.log("New class created:", classId, classData);

      try {
        // Get all enrolled students for this class
        const enrollmentsSnapshot = await db.collection("class_enrollments")
            .where("classId", "==", classId)
            .get();

        if (enrollmentsSnapshot.empty) {
          console.log("No students enrolled in this class");
          return;
        }

        // Collect all student IDs
        const studentIds = enrollmentsSnapshot.docs.map((doc) =>
          doc.data().studentId);
        console.log("Found enrolled students:", studentIds);

        // Get FCM tokens for all enrolled students
        const userTokensPromises = studentIds.map(async (studentId) => {
          const userDoc = await db.collection("users").doc(studentId).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            return userData.fcmToken;
          }
          return null;
        });

        const fcmTokens = (await Promise.all(userTokensPromises))
            .filter((token) => token !== null);
        console.log("Found FCM tokens:", fcmTokens.length);

        if (fcmTokens.length === 0) {
          console.log("No FCM tokens found for enrolled students");
          return;
        }

        // Create notification payload
        const notification = {
          title: "📚 New Class Scheduled!",
          body: `${classData.topic} with ${classData.teacher} on ` +
            `${classData.date} at ${classData.time}`,
          icon: "ic_launcher",
          color: "#4CAF50",
        };

        const data = {
          type: "new_class",
          classId: classId,
          topic: classData.topic || "",
          teacher: classData.teacher || "",
          date: classData.date || "",
          time: classData.time || "",
          link: classData.link || "",
        };

        // Send notification to all students
        const message = {
          notification: notification,
          data: data,
          tokens: fcmTokens,
          android: {
            notification: {
              channelId: "class_notifications",
              priority: "high",
              sound: "default",
            },
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: notification.title,
                  body: notification.body,
                },
                badge: 1,
                sound: "default",
              },
            },
          },
        };

        const response = await messaging.sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} ` +
          `notifications out of ${fcmTokens.length}`);

        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.error(
                  `Failed to send to token ${fcmTokens[idx]}:`,
                  resp.error,
              );
            }
          });
        }
      } catch (error) {
        console.error("Error sending class notification:", error);
      }
    },
);

// Cloud Function to send reminder notifications
exports.sendClassReminder = onCall(async (request) => {
  const {classId, reminderMinutes = 15} = request.data;

  if (!classId) {
    throw new HttpsError("invalid-argument", "classId is required");
  }

  try {
    // Get class data
    const classDoc = await db.collection("classes").doc(classId).get();
    if (!classDoc.exists) {
      throw new HttpsError("not-found", "Class not found");
    }

    const classData = classDoc.data();

    // Get enrolled students
    const enrollmentsSnapshot = await db.collection("class_enrollments")
        .where("classId", "==", classId)
        .get();

    if (enrollmentsSnapshot.empty) {
      console.log("No students enrolled in this class");
      return {success: false, message: "No students enrolled"};
    }

    // Get FCM tokens
    const studentIds = enrollmentsSnapshot.docs.map((doc) =>
      doc.data().studentId);
    const userTokensPromises = studentIds.map(async (studentId) => {
      const userDoc = await db.collection("users").doc(studentId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        return userData.fcmToken;
      }
      return null;
    });

    const fcmTokens = (await Promise.all(userTokensPromises))
        .filter((token) => token !== null);

    if (fcmTokens.length === 0) {
      return {success: false, message: "No FCM tokens found"};
    }

    // Create reminder notification
    const notification = {
      title: "⏰ Class Starting Soon!",
      body: `${classData.topic} starts in ${reminderMinutes} minutes. ` +
        "Get ready!",
      icon: "ic_launcher",
      color: "#FF9800",
    };

    const data = {
      type: "class_reminder",
      classId: classId,
      topic: classData.topic || "",
      teacher: classData.teacher || "",
      date: classData.date || "",
      time: classData.time || "",
      link: classData.link || "",
      reminderMinutes: reminderMinutes.toString(),
    };

    const message = {
      notification: notification,
      data: data,
      tokens: fcmTokens,
      android: {
        notification: {
          channelId: "reminder_notifications",
          priority: "high",
          sound: "default",
        },
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    console.log(`Reminder: Successfully sent ${response.successCount} ` +
      `notifications out of ${fcmTokens.length}`);

    return {
      success: true,
      message: `Sent ${response.successCount} reminders`,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error("Error sending reminder:", error);
    throw new HttpsError("internal", "Failed to send reminder");
  }
});

// Callable function for testing FCM notifications (requires auth - teachers only)
exports.testNotification = onCall(async (request) => {
  // Only authenticated teachers can send test notifications
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated to send test notifications");
  }

  const callerDoc = await db.collection("users").doc(request.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "teacher") {
    throw new HttpsError("permission-denied", "Only teachers can send test notifications");
  }

  const {
    fcmToken,
    title = "Test Notification",
    body = "This is a test message",
  } = request.data;

  if (!fcmToken) {
    throw new HttpsError("invalid-argument", "fcmToken is required");
  }

  try {
    const message = {
      notification: {
        title: title,
        body: body,
        icon: "ic_launcher",
      },
      data: {
        type: "test",
        timestamp: Date.now().toString(),
      },
      token: fcmToken,
      android: {
        notification: {
          channelId: "test_notifications",
          priority: "high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
          },
        },
      },
    };

    const response = await messaging.send(message);
    console.log("Test notification sent:", response);

    return {
      success: true,
      messageId: response,
      message: "Test notification sent successfully",
    };
  } catch (error) {
    console.error("Error sending test notification:", error);
    throw new HttpsError("internal", "Failed to send test notification");
  }
});

// Cloud Function to clean up expired FCM tokens
exports.cleanupExpiredTokens = onCall(async (request) => {
  try {
    const usersSnapshot = await db.collection("users").get();
    let cleanedCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (fcmToken) {
        try {
          // Try to send a test message to verify token validity
          await messaging.send({
            token: fcmToken,
            data: {test: "true"},
            dryRun: true, // This won't actually send the message
          });
        } catch (error) {
          if (error.code === "messaging/registration-token-not-registered" ||
              error.code === "messaging/invalid-registration-token") {
            // Remove invalid token
            await userDoc.ref.update({
              fcmToken: FieldValue.delete(),
            });
            cleanedCount++;
            console.log(`Removed invalid token for user ${userDoc.id}`);
          }
        }
      }
    }

    return {
      success: true,
      message: `Cleaned up ${cleanedCount} expired tokens`,
    };
  } catch (error) {
    console.error("Error cleaning up tokens:", error);
    throw new HttpsError("internal", "Failed to cleanup tokens");
  }
}); 