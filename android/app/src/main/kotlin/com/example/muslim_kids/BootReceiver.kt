package com.example.muslim_kids

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/**
 * Boot receiver that gets triggered when the device restarts
 * It initializes Flutter and calls the Dart callback to reschedule notifications
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
        private const val CHANNEL_NAME = "com.example.muslim_kids/boot_receiver"
        private const val SHARED_PREFS_NAME = "com.example.muslim_kids.PRAYER_ALARM_PREFS"
        private const val CALLBACK_HANDLE_KEY = "prayer_alarm_callback_handle"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "Device rebooted, rescheduling prayer notifications")

            // Get the callback handle from shared preferences
            val sharedPreferences = context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE)
            val callbackHandleString = sharedPreferences.getString(CALLBACK_HANDLE_KEY, null)

            if (callbackHandleString == null) {
                Log.e(TAG, "No callback handle found, cannot reschedule notifications")
                return
            }

            // Convert string to Long
            val callbackHandle: Long
            try {
                callbackHandle = callbackHandleString.toLong()
                if (callbackHandle == 0L) {
                    Log.e(TAG, "Invalid callback handle (0), cannot reschedule notifications")
                    return
                }
            } catch (e: NumberFormatException) {
                Log.e(TAG, "Invalid callback handle format: $callbackHandleString")
                return
            }

            // Initialize Flutter
            val flutterLoader = FlutterLoader()

            // Check if FlutterLoader is already initialized
            try {
                flutterLoader.startInitialization(context)
                flutterLoader.ensureInitializationComplete(context, null)
            } catch (e: Exception) {
                // FlutterLoader might already be initialized
                Log.w(TAG, "FlutterLoader initialization exception: ${e.message}")
                // Continue anyway
            }

            // Create a FlutterEngine
            val flutterEngine = FlutterEngine(context)

            // Start executing Dart code
            try {
                // Get the app bundle path
                val appBundlePath = try {
                    flutterLoader.findAppBundlePath()
                } catch (e: Exception) {
                    Log.w(TAG, "Error finding app bundle path: ${e.message}")
                    // Try to continue with a default path
                    "flutter_assets"
                }

                Log.i(TAG, "Using app bundle path: $appBundlePath")

                // Get the callback information
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
                if (callbackInfo == null) {
                    Log.e(TAG, "Callback not found for handle: $callbackHandle")
                    return
                }

                // For newer Flutter versions, we need to use DartExecutor directly
                val dartCallback = DartExecutor.DartCallback(
                    context.assets,
                    appBundlePath,
                    callbackInfo
                )

                // Execute the Dart callback
                flutterEngine.dartExecutor.executeDartCallback(dartCallback)

                Log.i(TAG, "Successfully executed Dart callback")
            } catch (e: Exception) {
                Log.e(TAG, "Error executing Dart callback: ${e.message}")
                e.printStackTrace()
                return
            }

            // Create a method channel to communicate with Dart
            val methodChannel = MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME)

            // Call the Dart method to reschedule notifications
            methodChannel.invokeMethod("rescheduleNotifications", null)

            Log.i(TAG, "Successfully triggered notification rescheduling")
        }
    }
}
