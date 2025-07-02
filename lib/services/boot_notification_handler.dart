import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:muslim_kids/services/prayer_alarm_service.dart';

/// This class handles rescheduling notifications after device reboot
class BootNotificationHandler {
  static const String tag = "BootNotificationHandler";
  static const String channelName = "com.example.muslim_kids/boot_receiver";
  static const String sharedPrefsName =
      "com.example.muslim_kids.PRAYER_ALARM_PREFS";
  static const String callbackHandleKey = "prayer_alarm_callback_handle";

  static const MethodChannel _channel = MethodChannel(channelName);

  /// Initialize the handler and register the callback
  static Future<void> initialize() async {
    // Register the callback handler
    _channel.setMethodCallHandler(_handleMethodCall);

    // Store the callback handle in shared preferences
    await _storeCallbackHandle();

    debugPrint('$tag Boot notification handler initialized');
  }

  /// Store the callback handle in shared preferences
  static Future<void> _storeCallbackHandle() async {
    try {
      final CallbackHandle? handle = PluginUtilities.getCallbackHandle(
        _rescheduleNotificationsCallback,
      );
      if (handle == null) {
        debugPrint('$tag Failed to get callback handle');
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Convert the callback handle to a string since it might be a 64-bit value
      await prefs.setString(callbackHandleKey, handle.toRawHandle().toString());

      debugPrint('$tag Stored callback handle: ${handle.toRawHandle()}');
    } catch (e) {
      debugPrint('$tag Error storing callback handle: $e');
    }
  }

  /// Handle method calls from the platform
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('$tag Received method call: ${call.method}');

    switch (call.method) {
      case 'rescheduleNotifications':
        return _rescheduleNotifications();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Reschedule all prayer notifications
  static Future<void> _rescheduleNotifications() async {
    debugPrint('$tag Rescheduling notifications after device reboot');

    try {
      // Initialize Flutter bindings if not already initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Wait a bit to ensure everything is properly initialized
      await Future.delayed(const Duration(seconds: 1));

      // Create and initialize the prayer alarm service
      final prayerAlarmService = PrayerAlarmService();

      // Schedule all prayer time notifications
      await prayerAlarmService.scheduleAllPrayerTimeNotifications();

      debugPrint('$tag Successfully rescheduled all prayer notifications');
    } catch (e) {
      debugPrint('$tag Error rescheduling notifications: $e');
    }
  }
}

/// This callback is called by the native code after device reboot
@pragma('vm:entry-point')
void _rescheduleNotificationsCallback() async {
  try {
    // This method needs to be annotated with @pragma('vm:entry-point')
    // to ensure it's not removed by the Dart compiler
    print(
      '${BootNotificationHandler.tag} Callback triggered',
    ); // Use print instead of debugPrint for early logging

    // Initialize Flutter
    WidgetsFlutterBinding.ensureInitialized();

    // Reschedule notifications
    await BootNotificationHandler._rescheduleNotifications();

    print(
      '${BootNotificationHandler.tag} Notifications rescheduled successfully',
    );
  } catch (e) {
    debugPrint('${BootNotificationHandler.tag} Error in callback: $e');
  }
}
