# 🚀 Firebase Cloud Functions Deployment Guide

## Prerequisites

### 1. **Firebase Blaze Plan Required** ⚠️
Firebase Cloud Functions require the **Blaze (pay-as-you-go) plan**. 

**Current Status**: `muslimkidsplatform` project needs upgrade
- Visit: https://console.firebase.google.com/project/muslimkidsplatform/usage/details
- Upgrade to Blaze plan to enable Cloud Functions deployment

### 2. **Service Account Permissions** 
You need "Service Account User" role:
- Visit: https://console.cloud.google.com/iam-admin/iam?project=muslimkidsplatform
- Ask a project Owner to assign your account this role

### 3. **Code Status** ✅
- All Cloud Functions code is complete and ready
- ESLint errors have been resolved
- Dependencies are correct

## Deployment Steps

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Deploy Functions (After Prerequisites)
```bash
firebase deploy --only functions
```

### 3. Test Functions
After deployment, you'll get URLs like:
- **sendClassNotification**: Auto-triggered when classes are created
- **sendClassReminder**: `https://[region]-muslimkidsplatform.cloudfunctions.net/sendClassReminder`
- **testNotification**: `https://[region]-muslimkidsplatform.cloudfunctions.net/testNotification`
- **cleanupExpiredTokens**: `https://[region]-muslimkidsplatform.cloudfunctions.net/cleanupExpiredTokens`

## 🧪 Testing FCM Notifications

### Test with HTTP Request
```bash
curl -X POST https://[region]-muslimkidsplatform.cloudfunctions.net/testNotification \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN_HERE",
    "title": "Test FCM",
    "body": "This is a test FCM notification!"
  }'
```

### Test Class Reminder
```javascript
// Call from your Flutter app
final httpsCallable = FirebaseFunctions.instance.httpsCallable('sendClassReminder');
final result = await httpsCallable.call({
  'classId': 'your_class_id',
  'reminderMinutes': 15
});
```

## 📱 Flutter App Updates

Your app is already configured with:
- ✅ FCM token storage in Firestore
- ✅ Foreground/background message handling  
- ✅ Notification channels for different types
- ✅ Auto-enrollment tracking for notifications

## 🔔 How It Works

1. **New Class**: When teacher creates class → Auto-sends notifications to enrolled students
2. **Reminders**: Call `sendClassReminder` function for custom timing
3. **Real-time**: Students get notifications instantly when app is open
4. **Background**: Notifications work when app is closed/minimized

## 🛠️ Troubleshooting

### Deployment Blocked?
1. **Blaze Plan Required**: Upgrade Firebase project to Blaze plan
2. **Permission Errors**: Ensure you have "Service Account User" role
3. **API Errors**: Blaze plan will enable required APIs automatically

### No Notifications Received?
1. Check FCM token in Firestore users collection
2. Verify students are enrolled in `class_enrollments` collection
3. Check function logs: `firebase functions:log`

## 🎯 Next Steps

### Immediate (Before Deployment)
1. **Upgrade to Blaze plan** at https://console.firebase.google.com/project/muslimkidsplatform/usage/details
2. **Grant Firebase permissions** (Service Account User role)

### After Deployment
1. **Test notifications** with the test endpoint
2. **Create a class** to trigger auto-notifications
3. **Call reminder function** for testing custom reminders
4. **Monitor logs** for any issues

## 💰 Cost Information

Firebase Blaze plan pricing:
- **Cloud Functions**: 
  - 2 million invocations per month free
  - $0.40 per million invocations after that
- **Firestore**: 
  - 50,000 reads, 20,000 writes, 20,000 deletes per day free
- **Firebase Hosting**: Free for up to 10GB storage and 360MB/day transfer

For a Muslim Kids app with moderate usage, monthly costs should be minimal (likely under $5/month).

Your FCM system is professionally implemented and ready for deployment once the Blaze plan is activated! 🚀 