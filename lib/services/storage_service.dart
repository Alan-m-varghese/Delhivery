import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shipment.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';
import '../models/notification_log.dart';

class StorageService {
  static const String shipmentsBoxName = 'shipments_box';
  static const String notificationsBoxName = 'notifications_box';

  static Box<Shipment>? _shipmentsBox;
  static Box<NotificationLog>? _notificationsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShipmentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StatusEventAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ShipmentAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NotificationLogAdapter());
    }

    _shipmentsBox = await Hive.openBox<Shipment>(shipmentsBoxName);
    _notificationsBox = await Hive.openBox<NotificationLog>(notificationsBoxName);
  }

  // Shipments Operations
  static List<Shipment> getAllShipments() {
    if (_shipmentsBox == null) return [];
    return _shipmentsBox!.values.toList();
  }

  static ValueListenable<Box<Shipment>> getShipmentsListenable() {
    return _shipmentsBox!.listenable();
  }

  static Shipment? getShipment(String id) {
    return _shipmentsBox?.get(id);
  }

  static Future<void> saveShipment(Shipment shipment) async {
    await _shipmentsBox?.put(shipment.id, shipment);
  }

  static Future<void> deleteShipment(String id) async {
    await _shipmentsBox?.delete(id);
  }

  // Notifications Operations
  static List<NotificationLog> getAllNotifications() {
    if (_notificationsBox == null) return [];
    final logs = _notificationsBox!.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  static ValueListenable<Box<NotificationLog>> getNotificationsListenable() {
    return _notificationsBox!.listenable();
  }

  static Future<void> addNotificationLog(NotificationLog log) async {
    await _notificationsBox?.put(log.id, log);
  }

  static Future<void> clearNotifications() async {
    await _notificationsBox?.clear();
  }

  // Clear all storage
  static Future<void> clearAllData() async {
    await _shipmentsBox?.clear();
    await _notificationsBox?.clear();
  }

  // Backup and Export JSON
  static String exportDataAsJson() {
    final shipments = getAllShipments().map((s) => s.toJson()).toList();
    final notifications = getAllNotifications().map((n) => n.toJson()).toList();

    final data = {
      'app': 'DELHIVERY',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'shipments': shipments,
      'notifications': notifications,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Restore and Import JSON
  static Future<bool> importDataFromJson(String jsonStr) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      if (decoded['shipments'] != null && decoded['shipments'] is List) {
        for (var item in decoded['shipments']) {
          final shipment = Shipment.fromJson(Map<String, dynamic>.from(item));
          await saveShipment(shipment);
        }
      }
      if (decoded['notifications'] != null && decoded['notifications'] is List) {
        for (var item in decoded['notifications']) {
          final log = NotificationLog.fromJson(Map<String, dynamic>.from(item));
          await addNotificationLog(log);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error importing JSON data: $e');
      return false;
    }
  }
}
