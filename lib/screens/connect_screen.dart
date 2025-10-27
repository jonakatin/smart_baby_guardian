import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bt = context.read<BluetoothService>();
      if (mounted) setState(() {});
      if (bt.isConnected) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Device')),
      floatingActionButton: bt.isConnected
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
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
                Text(
                  bt.isConnected
                      ? 'Connected: ${bt.device?.name ?? bt.device?.address}'
                      : 'Not Connected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: bt.discover(),
              builder: (context, snap) {
                final devices = snap.data ?? [];
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (devices.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No bonded Bluetooth devices.\nPair ESP32 (SPP) in system settings, then reopen.',
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final d = devices[i];
                    return ListTile(
                      title: Text(d.name ?? d.address),
                      subtitle: Text(d.address),
                      trailing:
                          bt.isConnecting && bt.device?.address == d.address
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (bt.device?.address == d.address && bt.isConnected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(Icons.link)),
                      onTap: () async {
                        try {
                          await bt.connect(d);
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/main');
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connect failed: $e')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
