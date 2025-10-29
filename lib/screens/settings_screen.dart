// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/bluetooth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final bt = context.watch<BluetoothService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const ListTile(title: Text('Appearance')),
          Card(
            child: Column(
              children: [
                RadioListTile(
                  title: const Text('System'),
                  value: 'system',
                  groupValue: store.settingsBox.get('themeMode'),
                  onChanged: (v) =>
                      setState(() => store.themeMode = ThemeMode.system),
                ),
                RadioListTile(
                  title: const Text('Light'),
                  value: 'light',
                  groupValue: store.settingsBox.get('themeMode'),
                  onChanged: (v) =>
                      setState(() => store.themeMode = ThemeMode.light),
                ),
                RadioListTile(
                  title: const Text('Dark'),
                  value: 'dark',
                  groupValue: store.settingsBox.get('themeMode'),
                  onChanged: (v) =>
                      setState(() => store.themeMode = ThemeMode.dark),
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
                    value: store.alarmVolume,
                    onChanged: (v) => setState(() => store.alarmVolume = v),
                  ),
                  trailing: Text('${(store.alarmVolume * 100).round()}%'),
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: store.vibration,
                  onChanged: (v) => setState(() => store.vibration = v),
                ),
                SwitchListTile(
                  title: const Text('Auto-acknowledge'),
                  value: store.autoAck,
                  onChanged: (v) => setState(() => store.autoAck = v),
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
                  value: store.autoConnect,
                  onChanged: (v) => setState(() => store.autoConnect = v),
                ),
                ListTile(
                  title: const Text('Data update rate'),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [1, 2, 5].map((s) {
                      final selected = store.updateRateSec == s;
                      return ChoiceChip(
                        label: Text('${s}s'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => store.updateRateSec = s),
                      );
                    }).toList(),
                  ),
                ),
                if (bt.isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilledButton.icon(
                      onPressed: () => bt.disconnect(),
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
                  onTap: () =>
                      Navigator.of(context).pushNamed('/main').then((_) {}),
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Reset to defaults'),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Reset settings?'),
                        content: const Text(
                          'This will reset theme, alerts, and Bluetooth preferences.',
                        ),
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
                    if (ok == true) {
                      store.settingsBox.clear();
                      await store.init();
                      if (mounted) setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ListTile(title: Text('About')),
          const Card(
            child: ListTile(
              title: Text('Smart Lab Guardian'),
              subtitle: Text(
                'Version 1.0.0\nSupervisor: Dr. Mary Nsabagwa\nGroup 28: Wambui Mariam, Johnson Makmot Kabira, Mwesigwa Isaac, Bataringaya Bridget, Jonathan Katongole',
              ),
              trailing: Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
    );
  }
}
