// ignore_for_file: unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/sensor_record.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/bluetooth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/alarm_handler.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
    Permission.notification, // For Android 13+
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();

  // Hive setup
  final Directory appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  Hive.registerAdapter(SensorRecordAdapter());
  await StorageService.instance.init();

  // Alarm handler init
  await AlarmHandler.instance.init();

  runApp(const SmartGuardianApp());
}

class SmartGuardianApp extends StatefulWidget {
  const SmartGuardianApp({super.key});
  @override
  State<SmartGuardianApp> createState() => _SmartGuardianAppState();
}

class _SmartGuardianAppState extends State<SmartGuardianApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _mode = StorageService.instance.themeMode;
    StorageService.instance.settingsStream.listen((_) {
      if (mounted) {
        setState(() {
          _mode = StorageService.instance.themeMode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BluetoothService())],
      child: MaterialApp(
        title: 'Smart Guardian',
        debugShowCheckedModeBanner: false,
        themeMode: _mode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routes: {
          '/': (_) => const SplashScreen(),
          '/connect': (_) => const ConnectScreen(),
          '/main': (_) => const MainScaffold(),
        },
      ),
    );
  }
}

/// Main scaffold with bottom navigation
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  final _pages = const [DashboardScreen(), HistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: StorageService.instance.settingsBox.listenable(),
      builder: (_, __, ___) {
        return Scaffold(
          body: _pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            onDestinationSelected: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}
