import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'delhivery_updates';
  static const _channelName = 'Shipment Updates';
  static const _channelDescription =
      'Notifications for shipment status changes detected during background refresh.';

  static Future<void> init() async {
    if (kIsWeb) return; // Local push notifications handled natively on mobile

    try {
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      await _plugin.initialize(initSettings);

      // Create the Android notification channel
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      );

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static Future<void> showStatusChangeNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD4FF4C), // Lime accent
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Notification show error: $e');
    }
  }
}
