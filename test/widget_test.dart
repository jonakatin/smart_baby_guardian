import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_baby_guard/services/bluetooth_service.dart';
import 'package:smart_baby_guard/screens/connect_screen.dart';

class _FakeBluetoothService extends BluetoothService {
  @override
  Future<void> ensureOn() async {}

  @override
  Future<List<BluetoothDevice>> discover() async {
    return [];
  }

  @override
  Future<void> connectDevice(BluetoothDevice device) async {}
}

void main() {
  testWidgets('Smart Temperature Guardian launches connect screen',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BluetoothService>(
              create: (_) => _FakeBluetoothService()),
        ],
        child: const MaterialApp(home: ConnectScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Smart Temperature Guardian'), findsOneWidget);
    expect(
        find.textContaining(
            'Select your SmartTemperatureGuardian device to connect'),
        findsOneWidget);
  });
}
