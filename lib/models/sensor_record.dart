import 'package:hive/hive.dart';

part 'sensor_record.g.dart';

@HiveType(typeId: 1)
class SensorRecord extends HiveObject {
  @HiveField(0)
  double distance;

  @HiveField(1)
  double temperature;

  @HiveField(2)
  int risk;

  @HiveField(3)
  String status;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  double tilt; // ← NEW tilt field (degrees from vertical)

  SensorRecord({
    required this.distance,
    required this.temperature,
    required this.risk,
    required this.status,
    required this.timestamp,
    required this.tilt,
  });

  factory SensorRecord.fromJson(Map<String, dynamic> json) {
    return SensorRecord(
      distance: (json['distance'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      risk: (json['risk'] ?? 0).toInt(),
      status: (json['status'] ?? 'SAFE').toString(),
      tilt: (json['tilt'] ?? 0).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        "distance": distance,
        "temperature": temperature,
        "risk": risk,
        "status": status,
        "tilt": tilt,
        "timestamp": timestamp.toIso8601String(),
      };
}
