// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_guardian/services/storage_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final data = StorageService.instance.allDesc;
    final avg = StorageService.instance.sessionAverages();
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          if (avg != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                child: ListTile(
                  title: const Text('Session Averages'),
                  subtitle: Text(
                    'Temperature: ${avg.$1.toStringAsFixed(1)} °C · Risk: ${avg.$2.toStringAsFixed(1)}%',
                  ),
                  trailing: const Icon(Icons.equalizer),
                ),
              ),
            ),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No records yet.'))
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final r = data[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.statusColor(r.risk),
                          child: Text(
                            r.risk.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${r.distance.toStringAsFixed(1)} cm  |  ${r.temperature.toStringAsFixed(1)} °C',
                        ),
                        subtitle: Text(
                          '${r.status} · ${DateFormat('yyyy-MM-dd HH:mm:ss').format(r.timestamp)}',
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: data.isEmpty ? null : _exportCsv,
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Export CSV'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: data.isEmpty
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Clear history?'),
                                  content: const Text(
                                    'This will delete all saved readings (keeps future ones).',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await StorageService.instance.clearHistory();
                                if (mounted) setState(() {});
                              }
                            },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final records = StorageService.instance.allDesc;
    final rows = <String>[
      'timestamp,distance_cm,temperature_c,tilt_deg,risk,status',
      for (final r in records)
        '${r.timestamp.toIso8601String()},${r.distance.toStringAsFixed(2)},${r.temperature.toStringAsFixed(2)},${r.tilt.toStringAsFixed(2)},${r.risk},${r.status}',
    ];
    final csv = rows.join('\n');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/smart_guardian_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Smart Guardian – CSV Export');
  }
}
