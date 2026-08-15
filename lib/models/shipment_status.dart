import 'package:hive/hive.dart';

part 'shipment_status.g.dart';

@HiveType(typeId: 0)
enum ShipmentStatus {
  @HiveField(0)
  ordered,

  @HiveField(1)
  shipped,

  @HiveField(2)
  outForDelivery,

  @HiveField(3)
  delivered,

  @HiveField(4)
  delayed,

  @HiveField(5)
  unknown;

  String get displayName {
    switch (this) {
      case ShipmentStatus.ordered:
        return 'Ordered';
      case ShipmentStatus.shipped:
        return 'Shipped';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.delayed:
        return 'Delayed';
      case ShipmentStatus.unknown:
        return 'Unknown';
    }
  }

  int get stepOrder {
    switch (this) {
      case ShipmentStatus.ordered:
        return 0;
      case ShipmentStatus.shipped:
        return 1;
      case ShipmentStatus.outForDelivery:
        return 2;
      case ShipmentStatus.delivered:
        return 3;
      case ShipmentStatus.delayed:
        return 1;
      case ShipmentStatus.unknown:
        return 0;
    }
  }
}
