import 'package:hive/hive.dart';

class Reading extends HiveObject {
  Reading({required this.timestamp, required this.temperature, required this.distance});

  final DateTime timestamp;
  final double temperature;
  final double distance;
}

class ReadingAdapter extends TypeAdapter<Reading> {
  @override
  final int typeId = 1;

  @override
  Reading read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final numOfFields = reader.readByte();
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Reading(
      timestamp: fields[0] as DateTime,
      temperature: fields[1] as double,
      distance: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Reading obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.distance);
  }
}
