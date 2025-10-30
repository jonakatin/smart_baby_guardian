import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../services/alert_service.dart';
import '../services/bluetooth_service.dart';

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
        title: const Text('Smart Baby Guard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Disconnect',
            onPressed: () => context.read<BluetoothService>().disconnect(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer2<BluetoothService, AlertService>(
            builder: (context, bluetooth, alert, _) {
              final reading = bluetooth.latestReading;
              final bool highTemp = (reading?.temperature ?? 0) > 37;
              final distanceValue = reading?.distance ?? double.infinity;
              final bool closeDistance = distanceValue < 15;
              final bool criticalDistance = distanceValue < 10;

              String? alertMessage;
              if (highTemp && closeDistance) {
                alertMessage = '⚠ Temperature too high and baby too close';
              } else if (highTemp) {
                alertMessage = '⚠ Temperature too high';
              } else if (closeDistance) {
                alertMessage = '⚠ Baby too close';
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< HEAD
                    Row(
                      children: [
                        const Text(
                          '🍼 Smart Baby Guard',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
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
                          bluetooth.isConnected
                              ? 'Connected'
                              : (bluetooth.isConnecting
                                  ? 'Connecting…'
                                  : 'Disconnected'),
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
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bluetooth.bannerMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    if (bluetooth.bannerMessage != null)
                      const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DataCard(
                            title: 'Current Temperature',
                            icon: '🌡',
                            value: reading != null
                                ? '${reading.temperature.toStringAsFixed(1)} °C'
                                : '--',
                            background: highTemp
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            valueStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: highTemp
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DataCard(
                            title: 'Current Distance',
                            icon: '📏',
                            value: reading != null
                                ? '${reading.distance.toStringAsFixed(1)} cm'
                                : '--',
                            background: criticalDistance
                                ? Theme.of(context).colorScheme.errorContainer
                                : closeDistance
                                    ? Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                            valueStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: criticalDistance
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer
                                  : closeDistance
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (alertMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          alertMessage,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (alertMessage == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          reading == null
                              ? 'Waiting for data…'
                              : 'All readings look safe.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Alerts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _AlertToggle(
                            label: 'Sound',
                            icon: Icons.volume_up,
                            value: alert.soundEnabled,
                            onChanged: alert.setSoundEnabled,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AlertToggle(
                            label: 'Flash',
                            icon: Icons.flash_on,
                            value: alert.flashEnabled,
                            onChanged: alert.setFlashEnabled,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AlertToggle(
                            label: 'Vibrate',
                            icon: Icons.vibration,
                            value: alert.vibrateEnabled,
                            onChanged: alert.setVibrateEnabled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Info',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
=======
                  Row(
                    children: [
                      const Text(
                        '🍼 Smart Baby Guard',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(
                        bluetooth.isConnected ? Icons.circle : Icons.circle_outlined,
                        color: bluetooth.isConnected
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bluetooth.isConnected ? 'Connected' : (bluetooth.isConnecting ? 'Connecting…' : 'Disconnected'),
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
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bluetooth.bannerMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (bluetooth.bannerMessage != null) const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DataCard(
                          title: 'Current Temperature',
                          icon: '🌡',
                          value: reading != null ? '${reading.temperature.toStringAsFixed(1)} °C' : '--',
                          background: highTemp
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: highTemp
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DataCard(
                          title: 'Current Distance',
                          icon: '📏',
                          value: reading != null ? '${reading.distance.toStringAsFixed(1)} cm' : '--',
                          background: criticalDistance
                              ? Theme.of(context).colorScheme.errorContainer
                              : closeDistance
                                  ? Theme.of(context).colorScheme.tertiaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: criticalDistance
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : closeDistance
                                    ? Theme.of(context).colorScheme.onTertiaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (alertMessage != null)
>>>>>>> 4ad3876e6bc5a6194832929fb87acb974b9ff17e
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
<<<<<<< HEAD
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Device: ${bluetooth.device?.name ?? 'SmartBabyGuard'}'),
                          const SizedBox(height: 4),
                          Text(
                              'Status: ${bluetooth.isConnected ? 'Connected' : 'Disconnected'}'),
                        ],
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
=======
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        alertMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (alertMessage == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        reading == null
                            ? 'Waiting for data…'
                            : 'All readings look safe.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _AlertToggle(
                          label: 'Sound',
                          icon: Icons.volume_up,
                          value: alert.soundEnabled,
                          onChanged: alert.setSoundEnabled,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AlertToggle(
                          label: 'Flash',
                          icon: Icons.flash_on,
                          value: alert.flashEnabled,
                          onChanged: alert.setFlashEnabled,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AlertToggle(
                          label: 'Vibrate',
                          icon: Icons.vibration,
                          value: alert.vibrateEnabled,
                          onChanged: alert.setVibrateEnabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connection Info',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Device: ${bluetooth.device?.name ?? 'SmartBabyGuard'}'),
                        const SizedBox(height: 4),
                        Text('Status: ${bluetooth.isConnected ? 'Connected' : 'Disconnected'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/history'),
                      icon: const Icon(Icons.history),
                      label: const Text('View History'),
                    ),
                  ),
                ],
>>>>>>> 4ad3876e6bc5a6194832929fb87acb974b9ff17e
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.background,
    required this.valueStyle,
  });

  final String title;
  final String icon;
  final String value;
  final Color background;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $title', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: valueStyle),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
<<<<<<< HEAD
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
=======
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
>>>>>>> 4ad3876e6bc5a6194832929fb87acb974b9ff17e
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
