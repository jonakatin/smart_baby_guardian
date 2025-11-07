import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/alert_service.dart';
import '../services/bluetooth_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final bluetooth = context.watch<BluetoothService>();
    final alert = context.watch<AlertService>();
    final String soundPath = alert.soundFilePath ?? 'None selected';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Alerts',
            children: [
              ListTile(
                title: const Text('Alarm volume'),
                subtitle: Slider(
                  value: alert.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '${(alert.volume * 100).round()}%',
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
                title: const Text('Flashlight'),
                value: alert.flashEnabled,
                onChanged: alert.setFlashEnabled,
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                value: alert.vibrateEnabled,
                onChanged: alert.setVibrateEnabled,
              ),
              ListTile(
                title: const Text('Temperature threshold'),
                subtitle: Slider(
                  value: alert.temperatureThreshold,
                  min: 20,
                  max: 40,
                  divisions: 20,
                  label: '${alert.temperatureThreshold.toStringAsFixed(1)} °C',
                  onChanged: alert.setTemperatureThreshold,
                ),
                trailing: Text(
                  '${alert.temperatureThreshold.toStringAsFixed(1)} °C',
                ),
              ),
              ListTile(
                title: const Text('Distance threshold'),
                subtitle: Slider(
                  value: alert.distanceThreshold,
                  min: 5,
                  max: 60,
                  divisions: 22,
                  label: '${alert.distanceThreshold.toStringAsFixed(1)} cm',
                  onChanged: alert.setDistanceThreshold,
                ),
                trailing: Text(
                  '${alert.distanceThreshold.toStringAsFixed(1)} cm',
                ),
              ),
              ListTile(
                title: const Text('Custom alarm sound'),
                subtitle: Text(
                  soundPath == 'None selected'
                      ? soundPath
                      : _displayName(soundPath),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: FilledButton(
                  onPressed: () => _pickSoundFile(context),
                  child: const Text('Select'),
                ),
              ),
              SwitchListTile(
                title: const Text('Auto-acknowledge alerts'),
                value: storage.autoAck,
                onChanged: (value) => storage.autoAck = value,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Bluetooth',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    onPressed: bluetooth.disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Appearance',
            children: [
              _buildThemeOption(
                context: context,
                mode: ThemeMode.system,
                selectedMode: storage.themeMode,
                label: 'System',
                icon: Icons.phone_iphone,
                onSelected: (mode) => storage.themeMode = mode,
              ),
              _buildThemeOption(
                context: context,
                mode: ThemeMode.light,
                selectedMode: storage.themeMode,
                label: 'Light',
                icon: Icons.light_mode,
                onSelected: (mode) => storage.themeMode = mode,
              ),
              _buildThemeOption(
                context: context,
                mode: ThemeMode.dark,
                selectedMode: storage.themeMode,
                label: 'Dark',
                icon: Icons.dark_mode,
                onSelected: (mode) => storage.themeMode = mode,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset to defaults'),
                onTap: () => _confirmReset(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AboutCard(),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode selectedMode,
    required String label,
    required IconData icon,
    required ValueChanged<ThemeMode> onSelected,
  }) {
    final selected = mode == selectedMode;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? colorScheme.primary : null),
      title: Text(label),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? colorScheme.primary : null,
      ),
      selected: selected,
      onTap: () => onSelected(mode),
    );
  }

  Future<void> _pickSoundFile(BuildContext context) async {
    final alert = context.read<AlertService>();
    try {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required.')),
          );
        }
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.first;
      String? path = file.path;
      if (path == null && file.bytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(file.name);
        final savedFile = File(p.join(directory.path, fileName));
        await savedFile.writeAsBytes(file.bytes!);
        path = savedFile.path;
      }
      if (path != null) {
        await alert.setSoundFilePath(path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alarm sound set to ${_displayName(path)}')),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select sound: $error')),
        );
      }
    }
  }

  static String _displayName(String path) {
    if (path.startsWith('content://')) {
      final uri = Uri.parse(path);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : path;
    }
    return p.basename(path);
  }

  Future<void> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text(
            'This will reset theme, alerts, thresholds, and Bluetooth preferences.'),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const ListTile(
        title: Text('Smart Temperature Guard'),
        subtitle: Text(
          'Supervisor: Dr. Mary Nsabagwa\n'
          'Group 28: Wambui Mariam, Johnson Makmot Kabira, Mwesigwa Isaac, '
          'Bataringaya Bridget, Jonathan Katongole',
        ),
        trailing: Icon(Icons.info_outline),
      ),
    );
  }
}
