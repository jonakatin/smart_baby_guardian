import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/alert_service.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final bluetooth = context.watch<BluetoothService>();
    final alert = context.watch<AlertService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const ListTile(title: Text('Appearance')),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  value: ThemeMode.system,
                  groupValue: storage.themeMode,
                  onChanged: (mode) {
                    if (mode != null) storage.themeMode = mode;
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: storage.themeMode,
                  onChanged: (mode) {
                    if (mode != null) storage.themeMode = mode;
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: storage.themeMode,
                  onChanged: (mode) {
                    if (mode != null) storage.themeMode = mode;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(title: Text('Alerts')),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Alarm volume'),
                  subtitle: Slider(
                    value: alert.volume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: alert.setVolume,
                  ),
                  trailing: Text('${(alert.volume * 100).round()}%'),
                ),
                SwitchListTile(
                  title: const Text('Sound'),
                  value: alert.soundEnabled,
                  onChanged: alert.setSoundEnabled,
                ),
                SwitchListTile(
                  title: const Text('Flash'),
                  value: alert.flashEnabled,
                  onChanged: alert.setFlashEnabled,
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: alert.vibrateEnabled,
                  onChanged: alert.setVibrateEnabled,
                ),
                SwitchListTile(
                  title: const Text('Auto-acknowledge'),
                  value: storage.autoAck,
                  onChanged: (value) => storage.autoAck = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(title: Text('Bluetooth')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-connect last device'),
                  value: storage.autoConnect,
                  onChanged: (value) => storage.autoConnect = value,
                ),
                ListTile(
                  title: const Text('Data update rate'),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [1, 2, 5].map((seconds) {
                      final selected = storage.updateRateSec == seconds;
                      return ChoiceChip(
                        label: Text('${seconds}s'),
                        selected: selected,
                        onSelected: (_) => storage.updateRateSec = seconds,
                      );
                    }).toList(),
                  ),
                ),
                if (bluetooth.isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: FilledButton.icon(
                      onPressed: bluetooth.disconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(title: Text('Data')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Export data'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data export coming soon.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Reset to defaults'),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(title: Text('About')),
          Card(
            child: const ListTile(
              title: Text('Smart Baby Guard'),
              subtitle: Text(
                'Version 1.0.0\n'
                'Supervisor: Dr. Mary Nsabagwa\n'
                'Group 28: Wambui Mariam, Johnson Makmot Kabira, Mwesigwa Isaac, '
                'Bataringaya Bridget, Jonathan Katongole',
              ),
              trailing: Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text('This will reset theme, alerts, and Bluetooth preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true) {
      final storage = context.read<StorageService>();
      await storage.resetSettings();
      context.read<AlertService>().reloadFromStorage();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings restored to defaults.')),
        );
      }
    }
  }
}
