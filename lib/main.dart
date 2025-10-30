import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/connect_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'services/alert_service.dart';
import 'services/bluetooth_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.instance.init();
  runApp(const SmartBabyGuardApp());
}

class SmartBabyGuardApp extends StatelessWidget {
  const SmartBabyGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => AlertService()),
      ],
      child: MaterialApp(
        title: 'Smart Baby Guard',
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent, brightness: Brightness.light),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent, brightness: Brightness.dark),
        ),
        routes: {
          '/': (context) => const ConnectScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
