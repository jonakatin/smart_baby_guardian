import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String? _error;

  Future<void> _connect() async {
    final bluetooth = context.read<BluetoothService>();
    setState(() => _error = null);
    try {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      await bluetooth.connectTo();
      if (!mounted) {
        return;
      }
      if (bluetooth.isConnected) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is BluetoothConnectionException
          ? error.message
          : 'Unable to connect. Ensure SmartBabyGuard is paired and powered on.';
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothService>();
    final isBusy = bluetooth.isConnecting || bluetooth.isAutoReconnecting;
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Baby Guard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Connect to your SmartBabyGuard monitor to start tracking real-time temperature and distance.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          bluetooth.isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: bluetooth.isConnected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bluetooth.isConnected
                              ? 'SmartBabyGuard connected'
                              : 'SmartBabyGuard not connected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () {
                              if (bluetooth.isConnected) {
                                Navigator.of(context)
                                    .pushReplacementNamed('/dashboard');
                              } else {
                                _connect();
                              }
                            },
                      icon: Icon(bluetooth.isConnected
                          ? Icons.dashboard
                          : Icons.bluetooth_searching),
                      label: Text(bluetooth.isConnected
                          ? 'Go to Dashboard'
                          : 'Connect to SmartBabyGuard'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Tip: Pair the SmartBabyGuard device from Bluetooth settings before using the app.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
