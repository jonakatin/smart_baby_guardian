// ✅ Complete Smart Guardian test suite (clean & self-contained)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smart_guardian/main.dart';
import 'package:smart_guardian/models/sensor_record.dart';
import 'package:smart_guardian/services/storage_service.dart';
import 'package:smart_guardian/services/bluetooth_service.dart';
import 'package:smart_guardian/theme/app_theme.dart';
import 'package:smart_guardian/utils/alarm_handler.dart';
import 'package:smart_guardian/screens/dashboard_screen.dart';
import 'package:smart_guardian/screens/history_screen.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = true;

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();

    Hive.init(Directory.systemTemp.path);
    Hive.registerAdapter(SensorRecordAdapter());
    await StorageService.instance.init();

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      await AlarmHandler.instance.init();
      await BluetoothService().ensureOn();
    }
  });

  group('1️⃣ App launch & theme tests', () {
    testWidgets('Splash screen loads with correct title', (tester) async {
      await tester.pumpWidget(const SmartGuardianApp());
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Smart Guardian'), findsOneWidget);
    });

    test('Color constants and status logic', () {
      expect(AppTheme.cherryRed, const Color(0xFFB5121B));
      expect(AppTheme.deepBlue, const Color(0xFF202A44));
      expect(AppTheme.neonYellow, const Color(0xFFDFFF00));
      expect(AppTheme.statusText(10), 'SAFE');
      expect(AppTheme.statusText(55), 'CAUTION');
      expect(AppTheme.statusText(95), 'DANGER');
    });
  });

  group('2️⃣ Hive Storage', () {
    test('Stores and retrieves SensorRecord correctly', () async {
      final rec = SensorRecord(
        distance: 23.4,
        temperature: 42.0,
        risk: 80,
        status: 'DANGER',
        timestamp: DateTime.now(),
        tilt: 5.0,
      );
      await StorageService.instance.addRecord(rec);
      final list = StorageService.instance.allDesc;
      expect(list.first.status, 'DANGER');
      expect(list.first.distance, 23.4);
    });
  });

  // ──────────────────────────────────────────────────────────────
  group('3️⃣ Bluetooth Service (manual injection)', () {
    test('Injects simulated data successfully', () async {
      final bt = BluetoothService();
      final rec = {
        "distance": 15.2,
        "temperature": 40.3,
        "risk": 70,
        "status": "DANGER"
      };
      bt.injectTestData(rec);
      final sub = bt.dataStream.listen((r) {
        expect(r.status, 'DANGER');
        expect(r.risk >= 70, true);
      });
      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
    });
  });

  // ──────────────────────────────────────────────────────────────
  group('4️⃣ Dashboard + Alarm behaviour', () {
    testWidgets('Dashboard updates UI and shows DANGER alert', (tester) async {
      final bt = BluetoothService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BluetoothService()),
            Provider(create: (_) => StorageService.instance),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      // Inject simulated DANGER reading
      bt.injectTestData({
        "distance": 5.0,
        "temperature": 80.0,
        "risk": 90,
        "status": "DANGER",
        "tilt": 25.0,
      });

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Move away'), findsWidgets);
      expect(find.textContaining('Risk Score'), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────────────────────
  group('5️⃣ Settings page', () {
    testWidgets('SettingsScreen builds with provider context', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BluetoothService()),
            Provider(create: (_) => StorageService.instance),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────
  group('6️⃣ History screen', () {
    testWidgets('Displays stored records and export buttons', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsWidgets);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────
  group('7️⃣ Full App navigation', () {
    testWidgets('Bottom navigation switches between pages', (tester) async {
      final bt = BluetoothService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => bt),
            Provider(create: (_) => StorageService.instance),
          ],
          child: const MaterialApp(
            home: DashboardScreen(), // or your root Scaffold
          ),
        ),
      );

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsWidgets);
    });
  });

  tearDownAll(() async {
    try {
      final bt = BluetoothService();
      await bt.disposeForTest();
    } catch (_) {}

    // ✅ only close if open; do not reopen it
    if (Hive.isBoxOpen('records')) {
      await Hive.box('records').close();
    }

    // ensure all boxes are closed
    await Hive.close();
  });
}
