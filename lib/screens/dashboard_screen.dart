import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../services/alert_service.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_overlay.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<Reading>? _subscription;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bluetooth = context.read<BluetoothService>();
      final alert = context.read<AlertService>();
      _subscription = bluetooth.readingsStream.listen((reading) {
        unawaited(alert.handleReading(reading));
      });
      final latest = bluetooth.latestReading;
      if (latest != null) {
        unawaited(alert.handleReading(latest));
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Temperature Guardian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Disconnect',
            onPressed: () => context.read<BluetoothService>().disconnect(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer3<BluetoothService, AlertService, StorageService>(
          builder: (context, bluetooth, alert, storage, _) {
            final Reading? reading = bluetooth.latestReading;
            final double temperature = reading?.temperature ?? 0;
            final double distance = reading?.distance ?? double.infinity;
            final DateTime? timestamp = reading?.timestamp;

            const double cautionTempThreshold = 37;
            const double dangerTempThreshold = 38.5;
            const double cautionDistanceThreshold = 25;
            const double dangerDistanceThreshold = 15;

            final bool cautionTemp =
                reading != null && temperature >= cautionTempThreshold;
            final bool dangerTemp =
                reading != null && temperature >= dangerTempThreshold;
            final bool cautionDistance =
                reading != null && distance <= cautionDistanceThreshold;
            final bool dangerDistance =
                reading != null && distance <= dangerDistanceThreshold;

            int risk = 10;
            if (dangerTemp && dangerDistance) {
              risk = 80;
            } else if (cautionTemp && cautionDistance) {
              risk = 55;
            }
            final String status = AppTheme.statusText(risk);

            final bool attemptingConnection =
                bluetooth.isConnecting || bluetooth.isAutoReconnecting;
            final Widget banner = !bluetooth.isConnected
                ? StatusBanner(
                    risk: 55,
                    status: 'CAUTION',
                    message: attemptingConnection
                        ? 'Attempting to connect to SmartTemperatureGuardian…'
                        : 'Device disconnected. Open Connect to pair again.',
                  )
                : StatusBanner(risk: risk, status: status);

            final String connectionLabel;
            if (bluetooth.isConnected) {
              connectionLabel = 'Connected';
            } else if (bluetooth.isConnecting || bluetooth.isAutoReconnecting) {
              connectionLabel = 'Connecting…';
            } else {
              connectionLabel = 'Disconnected';
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '🍼 Smart Temperature Guardian',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Icon(
                            bluetooth.isConnected
                                ? Icons.circle
                                : Icons.circle_outlined,
                            color: bluetooth.isConnected
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            connectionLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: bluetooth.isConnected
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (bluetooth.bannerMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bluetooth.bannerMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      if (bluetooth.bannerMessage != null)
                        const SizedBox(height: 16),
                      banner,
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool wide = constraints.maxWidth > 680;
                          final temperatureCard = SensorCard(
                            title: 'Current Temperature',
                            value: reading != null
                                ? '${temperature.toStringAsFixed(1)} °C'
                                : '--',
                            icon: Icons.thermostat,
                            color: dangerTemp
                                ? Theme.of(context).colorScheme.error
                                : cautionTemp
                                    ? Theme.of(context).colorScheme.tertiary
                                    : null,
                          );
                          final distanceCard = SensorCard(
                            title: 'Current Distance',
                            value: reading != null
                                ? '${distance.toStringAsFixed(1)} cm'
                                : '--',
                            icon: Icons.social_distance,
                            color: dangerDistance
                                ? Theme.of(context).colorScheme.error
                                : cautionDistance
                                    ? Theme.of(context).colorScheme.tertiary
                                    : null,
                          );
                          if (wide) {
                            return Row(
                              children: [
                                Expanded(child: temperatureCard),
                                const SizedBox(width: 12),
                                Expanded(child: distanceCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              temperatureCard,
                              const SizedBox(height: 12),
                              distanceCard,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SensorCard(
                        title: 'Last Reading',
                        value: timestamp != null
                            ? timestamp.toLocal().toString().split('.').first
                            : 'Awaiting data…',
                        icon: Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Alerts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double maxWidth = constraints.maxWidth;
                          final double tileWidth =
                              maxWidth > 720 ? 220 : maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: tileWidth,
                                child: _AlertToggle(
                                  label: 'Sound',
                                  icon: Icons.volume_up,
                                  value: alert.soundEnabled,
                                  onChanged: alert.setSoundEnabled,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: _AlertToggle(
                                  label: 'Flash',
                                  icon: Icons.flash_on,
                                  value: alert.flashEnabled,
                                  onChanged: alert.setFlashEnabled,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: _AlertToggle(
                                  label: 'Vibrate',
                                  icon: Icons.vibration,
                                  value: alert.vibrateEnabled,
                                  onChanged: alert.setVibrateEnabled,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connection Info',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Device: ${bluetooth.device?.name ?? 'SmartTemperatureGuardian'}'),
                              const SizedBox(height: 4),
                              Text('Status: $connectionLabel'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/history'),
                          icon: const Icon(Icons.history),
                          label: const Text('View History'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (alert.alertActive && !storage.autoAck)
                  AlarmOverlay(
                    onAcknowledge: () => alert.acknowledgeAlert(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertToggle extends StatelessWidget {
  const _AlertToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          title: Text(label),
          secondary: Icon(icon),
        ),
      ),
    );
  }
}
