// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorRecordAdapter extends TypeAdapter<SensorRecord> {
  @override
  final int typeId = 1;

  @override
  SensorRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorRecord(
      distance: fields[0] as double,
      temperature: fields[1] as double,
      risk: fields[2] as int,
      status: fields[3] as String,
      timestamp: fields[4] as DateTime,
      tilt: (fields[5] as double?) ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, SensorRecord obj) {
    writer
      ..writeByte(6) // total fields
      ..writeByte(0)
      ..write(obj.distance)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.risk)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.tilt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
