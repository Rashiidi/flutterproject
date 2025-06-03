import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this once (e.g., in your main screen's initState)
  static Future<void> initialize(BuildContext context) async {
    // Request notification permissions (especially for iOS)
    await _messaging.requestPermission();

    // Get the device token (for sending targeted notifications)
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = message.notification!;
        // Show a dialog or snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title ?? ''}\n${notification.body ?? ''}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    // Optionally handle background and terminated state messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap when app is in background
      // You can navigate to a specific screen here if needed
    });
  }
}