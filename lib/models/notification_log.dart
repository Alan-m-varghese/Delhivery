import 'package:hive/hive.dart';
import 'shipment_status.dart';

part 'notification_log.g.dart';

@HiveType(typeId: 3)
class NotificationLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String shipmentId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final ShipmentStatus status;

  NotificationLog({
    required this.id,
    required this.shipmentId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipmentId': shipmentId,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };

  factory NotificationLog.fromJson(Map<String, dynamic> json) => NotificationLog(
        id: json['id'],
        shipmentId: json['shipmentId'],
        title: json['title'],
        body: json['body'],
        timestamp: DateTime.parse(json['timestamp']),
        status: ShipmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ShipmentStatus.unknown,
        ),
      );
}
