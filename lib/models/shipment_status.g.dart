// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShipmentStatusAdapter extends TypeAdapter<ShipmentStatus> {
  @override
  final int typeId = 0;

  @override
  ShipmentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShipmentStatus.ordered;
      case 1:
        return ShipmentStatus.shipped;
      case 2:
        return ShipmentStatus.outForDelivery;
      case 3:
        return ShipmentStatus.delivered;
      case 4:
        return ShipmentStatus.delayed;
      case 5:
        return ShipmentStatus.unknown;
      default:
        return ShipmentStatus.ordered;
    }
  }

  @override
  void write(BinaryWriter writer, ShipmentStatus obj) {
    switch (obj) {
      case ShipmentStatus.ordered:
        writer.writeByte(0);
        break;
      case ShipmentStatus.shipped:
        writer.writeByte(1);
        break;
      case ShipmentStatus.outForDelivery:
        writer.writeByte(2);
        break;
      case ShipmentStatus.delivered:
        writer.writeByte(3);
        break;
      case ShipmentStatus.delayed:
        writer.writeByte(4);
        break;
      case ShipmentStatus.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipmentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
