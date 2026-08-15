// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShipmentAdapter extends TypeAdapter<Shipment> {
  @override
  final int typeId = 2;

  @override
  Shipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shipment(
      id: fields[0] as String,
      platform: fields[1] as String,
      courier: fields[2] as String,
      trackingId: fields[3] as String,
      trackingUrl: fields[4] as String,
      itemName: fields[5] as String?,
      status: fields[6] as ShipmentStatus,
      timeline: (fields[7] as List).cast<StatusEvent>(),
      isAutoTracked: fields[8] as bool,
      lastChecked: fields[9] as DateTime,
      estimatedDelivery: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Shipment obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.courier)
      ..writeByte(3)
      ..write(obj.trackingId)
      ..writeByte(4)
      ..write(obj.trackingUrl)
      ..writeByte(5)
      ..write(obj.itemName)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.timeline)
      ..writeByte(8)
      ..write(obj.isAutoTracked)
      ..writeByte(9)
      ..write(obj.lastChecked)
      ..writeByte(10)
      ..write(obj.estimatedDelivery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
