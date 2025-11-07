import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/sensor_record.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ValueListenableBuilder<Box<SensorRecord>>(
        valueListenable: StorageService.instance.listenable,
        builder: (context, box, _) {
          final readings = StorageService.instance.getRecords();
          if (readings.isEmpty) {
            return const Center(
              child: Text('No readings recorded yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final reading = readings[index];
              return ListTile(
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(dateFormat.format(reading.timestamp)),
                subtitle: Text(
                  'Temperature: ${reading.temperature.toStringAsFixed(1)} °C\n'
                  'Distance: ${reading.distance.toStringAsFixed(1)} cm',
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: readings.length,
          );
        },
      ),
    );
  }
}
