import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/main.dart';
import '../lib/services/alert_service.dart';

// Stub BluetoothService for widget tests (original package file not present)
class BluetoothService extends ChangeNotifier {
  BluetoothService();
}

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
    expect(find.textContaining('Connect to your SmartBabyGuard monitor'),
        findsOneWidget);
  });
}
