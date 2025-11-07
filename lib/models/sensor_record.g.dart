// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_record.dart';

class SensorRecordAdapter extends TypeAdapter<SensorRecord> {
  @override
  final int typeId = 1;

  @override
  SensorRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SensorRecord(
      temperature: (fields[0] as num).toDouble(),
      distance: (fields[1] as num).toDouble(),
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SensorRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.temperature)
      ..writeByte(1)
      ..write(obj.distance)
      ..writeByte(2)
      ..write(obj.timestamp);
  }
}
