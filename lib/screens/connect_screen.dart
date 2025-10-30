import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/permission_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  Future<List<BluetoothDevice>>? _devicesFuture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDevices();
      final bluetooth = context.read<BluetoothService>();
      if (bluetooth.isConnected && mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  Future<void> _loadDevices() async {
    final bluetooth = context.read<BluetoothService>();
    setState(() {
      _devicesFuture = bluetooth.discover();
    });
    _initialized = true;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final bluetooth = context.read<BluetoothService>();
    try {
      final granted = await PermissionService.requestBluetoothPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth permissions are required to connect to SmartBabyGuard.',
            ),
          ),
        );
        return;
      }
      await bluetooth.connectDevice(device);
      if (!mounted) return;
      if (bluetooth.isConnected) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (error) {
      debugPrint('Bluetooth connection failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to connect. Please ensure the device is powered on and nearby, then try again.',
          ),
        ),
      );
    }
  }

  Future<void> _refreshDevices() async {
    await _loadDevices();
    final future = _devicesFuture;
    if (future != null) {
      await future;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothService>();
    final bool isBusy = bluetooth.isConnecting || bluetooth.isAutoReconnecting;
    final future = _devicesFuture;
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Baby Guard')),
      floatingActionButton: bluetooth.isConnected
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bluetooth, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bluetooth.isConnected
                        ? 'Connected: ${bluetooth.device?.name ?? bluetooth.device?.address}'
                        : 'Select your SmartBabyGuard device to connect.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh devices',
                  onPressed: isBusy ? null : _refreshDevices,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BluetoothDevice>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.none &&
                    !_initialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No bonded Bluetooth devices found. Pair the SmartBabyGuard (SPP) device in system settings then refresh.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, index) {
                    final device = devices[index];
                    final bool isSelected =
                        bluetooth.device?.address == device.address;
                    final bool isConnectingToDevice =
                        bluetooth.isConnecting && isSelected;
                    return ListTile(
                      title: Text(device.name ?? device.address),
                      subtitle: Text(device.address),
                      trailing: isConnectingToDevice
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : isSelected && bluetooth.isConnected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.link),
                      onTap: isBusy ? null : () => _connectToDevice(device),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Smart Baby Guardian – Supervisor: Dr. Mary Nsabagwa\nGroup 28: Wambui Mariam, Johnson Makmot Kabira, Mwesigwa Isaac, Bataringaya Bridget, Jonathan Katongole',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
