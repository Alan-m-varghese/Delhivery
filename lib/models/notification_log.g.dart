// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationLogAdapter extends TypeAdapter<NotificationLog> {
  @override
  final int typeId = 3;

  @override
  NotificationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationLog(
      id: fields[0] as String,
      shipmentId: fields[1] as String,
      title: fields[2] as String,
      body: fields[3] as String,
      timestamp: fields[4] as DateTime,
      status: fields[5] as ShipmentStatus,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shipmentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
