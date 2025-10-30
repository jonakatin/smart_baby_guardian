import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

<<<<<<< HEAD
import '../lib/main.dart';
import '../lib/services/alert_service.dart';

// Stub BluetoothService for widget tests (original package file not present)
class BluetoothService extends ChangeNotifier {
  BluetoothService();
}
=======
import 'package:smart_baby_guard/main.dart';
import 'package:smart_baby_guard/services/alert_service.dart';
import 'package:smart_baby_guard/services/bluetooth_service.dart';
>>>>>>> 4ad3876e6bc5a6194832929fb87acb974b9ff17e

void main() {
  testWidgets('Smart Baby Guard launches connect screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BluetoothService()),
          ChangeNotifierProvider(create: (_) => AlertService()),
        ],
        child: const SmartBabyGuardApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Smart Baby Guard'), findsOneWidget);
<<<<<<< HEAD
    expect(find.textContaining('Connect to your SmartBabyGuard monitor'),
        findsOneWidget);
=======
    expect(find.textContaining('Connect to your SmartBabyGuard monitor'), findsOneWidget);
>>>>>>> 4ad3876e6bc5a6194832929fb87acb974b9ff17e
  });
}
