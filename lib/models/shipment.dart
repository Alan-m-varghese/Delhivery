import 'package:hive/hive.dart';
import 'shipment_status.dart';
import 'status_event.dart';

part 'shipment.g.dart';

@HiveType(typeId: 2)
class Shipment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String platform; // Amazon, Flipkart, Myntra, Ajio, Purplle, Other

  @HiveField(2)
  final String courier; // Delhivery, DTDC, India Post, Ecom Express, Blue Dart, Unknown

  @HiveField(3)
  final String trackingId;

  @HiveField(4)
  final String trackingUrl;

  @HiveField(5)
  String? itemName;

  @HiveField(6)
  ShipmentStatus status;

  @HiveField(7)
  List<StatusEvent> timeline;

  @HiveField(8)
  bool isAutoTracked;

  @HiveField(9)
  DateTime lastChecked;

  @HiveField(10)
  DateTime? estimatedDelivery;

  Shipment({
    required this.id,
    required this.platform,
    required this.courier,
    required this.trackingId,
    required this.trackingUrl,
    this.itemName,
    required this.status,
    required this.timeline,
    required this.isAutoTracked,
    required this.lastChecked,
    this.estimatedDelivery,
  });

  Shipment copyWith({
    String? id,
    String? platform,
    String? courier,
    String? trackingId,
    String? trackingUrl,
    String? itemName,
    ShipmentStatus? status,
    List<StatusEvent>? timeline,
    bool? isAutoTracked,
    DateTime? lastChecked,
    DateTime? estimatedDelivery,
  }) {
    return Shipment(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      courier: courier ?? this.courier,
      trackingId: trackingId ?? this.trackingId,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      itemName: itemName ?? this.itemName,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      isAutoTracked: isAutoTracked ?? this.isAutoTracked,
      lastChecked: lastChecked ?? this.lastChecked,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'courier': courier,
        'trackingId': trackingId,
        'trackingUrl': trackingUrl,
        'itemName': itemName,
        'status': status.name,
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'isAutoTracked': isAutoTracked,
        'lastChecked': lastChecked.toIso8601String(),
        'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      };

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['id'],
        platform: json['platform'],
        courier: json['courier'],
        trackingId: json['trackingId'],
        trackingUrl: json['trackingUrl'],
        itemName: json['itemName'],
        status: ShipmentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ShipmentStatus.unknown,
        ),
        timeline: (json['timeline'] as List)
            .map((e) => StatusEvent.fromJson(e))
            .toList(),
        isAutoTracked: json['isAutoTracked'] ?? false,
        lastChecked: DateTime.parse(json['lastChecked']),
        estimatedDelivery: json['estimatedDelivery'] != null
            ? DateTime.parse(json['estimatedDelivery'])
            : null,
      );
}
