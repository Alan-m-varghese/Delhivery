import 'package:hive/hive.dart';
import 'shipment_status.dart';

part 'status_event.g.dart';

@HiveType(typeId: 1)
class StatusEvent extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final ShipmentStatus status;

  @HiveField(2)
  final String? location;

  @HiveField(3)
  final String? description;

  StatusEvent({
    required this.timestamp,
    required this.status,
    this.location,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'location': location,
        'description': description,
      };

  factory StatusEvent.fromJson(Map<String, dynamic> json) => StatusEvent(
        timestamp: DateTime.parse(json['timestamp']),
        status: ShipmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ShipmentStatus.unknown,
        ),
        location: json['location'],
        description: json['description'],
      );
}
