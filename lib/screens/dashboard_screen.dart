import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_record.dart';
import '../services/alert_service.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_overlay.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';

enum HistoryRange { hour, day, week }

extension _HistoryRangeExtension on HistoryRange {
  Duration get duration {
    switch (this) {
      case HistoryRange.hour:
        return const Duration(hours: 1);
      case HistoryRange.day:
        return const Duration(days: 1);
      case HistoryRange.week:
        return const Duration(days: 7);
    }
  }

  String get label {
    switch (this) {
      case HistoryRange.hour:
        return 'Past Hour';
      case HistoryRange.day:
        return 'Past Day';
      case HistoryRange.week:
        return 'Past Week';
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<SensorRecord>? _subscription;
  bool _initialized = false;
  HistoryRange _range = HistoryRange.hour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bluetooth = context.read<BluetoothService>();
      final alert = context.read<AlertService>();
      _subscription = bluetooth.readingsStream.listen(alert.handleReading);
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
    final storage = context.watch<StorageService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Temperature Guard'),
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
            final SensorRecord? reading = bluetooth.latestReading;
            final double temperature = reading?.temperature ?? 0;
            final double distance = reading?.distance ?? double.infinity;
            final DateTime? timestamp = reading?.timestamp;

            final double tempThreshold = alert.temperatureThreshold;
            final double distanceThreshold = alert.distanceThreshold;

            final bool temperatureAlert =
                reading != null && temperature >= tempThreshold;
            final bool distanceAlert =
                reading != null && distance <= distanceThreshold;

            final int risk;
            if (temperatureAlert && distanceAlert) {
              risk = 80;
            } else if (temperatureAlert || distanceAlert) {
              risk = 55;
            } else {
              risk = 10;
            }

            final bool attemptingConnection =
                bluetooth.isConnecting || bluetooth.isAutoReconnecting;
            final statusText = AppTheme.statusText(risk);
            final Widget banner = !bluetooth.isConnected
                ? StatusBanner(
                    risk: 55,
                    status: 'CAUTION',
                    message: attemptingConnection
                        ? 'Attempting to connect to SmartTemperatureGuard…'
                        : 'Device disconnected. Open Connect to pair again.',
                  )
                : StatusBanner(risk: risk, status: statusText);

            final String connectionLabel;
            if (bluetooth.isConnected) {
              connectionLabel = 'Connected';
            } else if (attemptingConnection) {
              connectionLabel = 'Connecting…';
            } else {
              connectionLabel = 'Disconnected';
            }

            return Stack(
              children: [
                ValueListenableBuilder<Box<SensorRecord>>(
                  valueListenable: storage.listenable,
                  builder: (context, box, _) {
                    final now = DateTime.now();
                    final since = now.subtract(_range.duration);
                    final records = storage.getRecords(since: since);
                    final stats = _buildStats(records);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '🍼 Smart Temperature Guard',
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
                                color: temperatureAlert
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              );
                              final distanceCard = SensorCard(
                                title: 'Current Distance',
                                value: reading != null
                                    ? '${distance.toStringAsFixed(1)} cm'
                                    : '--',
                                icon: Icons.social_distance,
                                color: distanceAlert
                                    ? Theme.of(context).colorScheme.error
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
                                ? DateFormat('MMM d, HH:mm:ss').format(
                                    timestamp.toLocal(),
                                  )
                                : 'Awaiting data…',
                            icon: Icons.access_time,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          _buildAlertToggles(context, alert),
                          const SizedBox(height: 24),
                          Text(
                            'History',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: HistoryRange.values.map((range) {
                              final bool selected = range == _range;
                              return ChoiceChip(
                                label: Text(range.label),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _range = range;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          _HistoryChartCard(records: records),
                          const SizedBox(height: 16),
                          _StatisticsGrid(stats: stats),
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
                    );
                  },
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

  Map<String, _Statistic> _buildStats(List<SensorRecord> records) {
    if (records.isEmpty) {
      return <String, _Statistic>{
        'temperature': const _Statistic.empty(),
        'distance': const _Statistic.empty(),
      };
    }
    final temperatures = records.map((r) => r.temperature).toList();
    final distances = records.map((r) => r.distance).toList();
    return <String, _Statistic>{
      'temperature': _Statistic(
        min: temperatures.reduce(min),
        max: temperatures.reduce(max),
        avg: temperatures.reduce((a, b) => a + b) / temperatures.length,
      ),
      'distance': _Statistic(
        min: distances.reduce(min),
        max: distances.reduce(max),
        avg: distances.reduce((a, b) => a + b) / distances.length,
      ),
    };
  }

  Widget _buildAlertToggles(BuildContext context, AlertService alert) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double tileWidth = maxWidth > 720 ? 220 : maxWidth;
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
      ],
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

class _Statistic {
  const _Statistic({required this.min, required this.max, required this.avg});

  const _Statistic.empty()
      : min = double.nan,
        max = double.nan,
        avg = double.nan;

  final double min;
  final double max;
  final double avg;

  bool get hasData => !min.isNaN && !max.isNaN && !avg.isNaN;
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.stats});

  final Map<String, _Statistic> stats;

  @override
  Widget build(BuildContext context) {
    final temperature = stats['temperature'] ?? const _Statistic.empty();
    final distance = stats['distance'] ?? const _Statistic.empty();

    Widget buildCard(String title, _Statistic stat, String unit) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: stat.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Text('Min: ${stat.min.toStringAsFixed(1)} $unit'),
                    Text('Max: ${stat.max.toStringAsFixed(1)} $unit'),
                    Text('Avg: ${stat.avg.toStringAsFixed(1)} $unit'),
                  ],
                )
              : const Text('No data recorded'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth > 600;
        if (wide) {
          return Row(
            children: [
              Expanded(child: buildCard('Temperature', temperature, '°C')),
              const SizedBox(width: 12),
              Expanded(child: buildCard('Distance', distance, 'cm')),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCard('Temperature', temperature, '°C'),
            const SizedBox(height: 12),
            buildCard('Distance', distance, 'cm'),
          ],
        );
      },
    );
  }
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({required this.records});

  final List<SensorRecord> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: records.length < 2
            ? const SizedBox(
                height: 220,
                child: Center(
                  child: Text('Waiting for enough sensor data to draw a graph.'),
                ),
              )
            : SizedBox(
                height: 260,
                child: _SensorChart(records: records),
              ),
      ),
    );
  }
}

class _SensorChart extends StatelessWidget {
  const _SensorChart({required this.records});

  final List<SensorRecord> records;

  @override
  Widget build(BuildContext context) {
    final spotsTemp = records
        .map((record) => FlSpot(
              record.timestamp.millisecondsSinceEpoch.toDouble(),
              record.temperature,
            ))
        .toList();
    final spotsDistance = records
        .map((record) => FlSpot(
              record.timestamp.millisecondsSinceEpoch.toDouble(),
              record.distance,
            ))
        .toList();

    final double minX = spotsTemp.first.x;
    final double maxX = spotsTemp.last.x;
    final double minTemp =
        records.map((r) => r.temperature).reduce(min).floorToDouble();
    final double maxTemp =
        records.map((r) => r.temperature).reduce(max).ceilToDouble();
    final double minDistance =
        records.map((r) => r.distance).reduce(min).floorToDouble();
    final double maxDistance =
        records.map((r) => r.distance).reduce(max).ceilToDouble();
    final double interval = (maxX - minX) <= 0 ? 1 : (maxX - minX) / 4;

    String formatTime(double value) {
      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      return DateFormat('HH:mm').format(date);
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surfaceVariant,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final label = spot.barIndex == 0 ? 'Temp' : 'Dist';
                final unit = spot.barIndex == 0 ? '°C' : 'cm';
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(1)} $unit',
                  Theme.of(context).textTheme.bodySmall!,
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formatTime(value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsTemp,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: spotsDistance,
            color: Theme.of(context).colorScheme.tertiary,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        minY: min(minTemp, minDistance),
        maxY: max(maxTemp, maxDistance),
      ),
    );
  }
}
