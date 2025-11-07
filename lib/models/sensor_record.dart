import 'package:hive/hive.dart';

part 'sensor_record.g.dart';

@HiveType(typeId: 1)
class SensorRecord extends HiveObject {
  SensorRecord({
    required this.temperature,
    required this.distance,
    required this.timestamp,
  });

  @HiveField(0)
  final double temperature;

  @HiveField(1)
  final double distance;

  @HiveField(2)
  final DateTime timestamp;
}
