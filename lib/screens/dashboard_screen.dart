import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';
import '../widgets/alarm_overlay.dart';
import '../utils/alarm_handler.dart';
import '../models/sensor_record.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SensorRecord? _last;
  StreamSubscription<SensorRecord>? _sub;
  bool _showAlert = false;

  @override
  void initState() {
    super.initState();
    final bt = context.read<BluetoothService>();
    _sub = bt.dataStream.listen(_onData);
  }

  void _onData(SensorRecord rec) async {
    setState(() => _last = rec);

    final danger =
        rec.risk >= 70 || rec.tilt >= 20; // ← tilt can also trigger alert
    if (danger) {
      if (!context.read<BluetoothService>().acknowledged) {
        setState(() => _showAlert = true);
        await AlarmHandler.instance.startAlarm(
          volume: StorageService.instance.alarmVolume,
          vibrate: StorageService.instance.vibration,
        );
      }
    } else {
      setState(() => _showAlert = false);
      await AlarmHandler.instance.stopAlarm();
      if (StorageService.instance.autoAck) {
        context.read<BluetoothService>().setAcknowledged(false);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    AlarmHandler.instance.stopAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothService>();
    final cs = Theme.of(context).colorScheme;
    final rec = _last;

    if (rec == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart Lab Guardian')),
        body: const Center(child: Text('Waiting for sensor data...')),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Smart Lab Guardian'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Chip(
                  label: Text(bt.isConnected ? 'Connected' : 'Offline',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: bt.isConnected ? Colors.green : cs.tertiary,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 220,
                      child: RiskGauge(percentage: rec.risk.toDouble()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─────────────── Sensor Cards ───────────────
                Row(
                  children: [
                    Expanded(
                      child: SensorCard(
                        title: 'Distance',
                        value: '${rec.distance.toStringAsFixed(1)} cm',
                        icon: Icons.social_distance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SensorCard(
                        title: 'Temperature',
                        value: '${rec.temperature.toStringAsFixed(1)} °C',
                        icon: Icons.thermostat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SensorCard(
                        title: 'Tilt',
                        value: '${rec.tilt.toStringAsFixed(1)}°',
                        icon: Icons.screen_rotation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SensorCard(
                        title: 'Status',
                        value: rec.status,
                        icon: Icons.warning,
                        color: AppTheme.statusColor(rec.risk),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatusBanner(risk: rec.risk, status: rec.status),
              ],
            ),
          ),
        ),
        if (_showAlert)
          AlarmOverlay(
            onAcknowledge: () async {
              context.read<BluetoothService>().setAcknowledged(true);
              await AlarmHandler.instance.stopAlarm();
              setState(() => _showAlert = false);
            },
          ),
      ],
    );
  }
}
