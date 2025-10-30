import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.smartbabyguard/permissions');

  static const List<String> _bluetoothPermissionKeys = <String>[
    'bluetooth',
    'bluetoothScan',
    'bluetoothConnect',
    'locationWhenInUse',
  ];

  static const List<String> _cameraPermissionKeys = <String>[
    'camera',
  ];

  static Future<bool> requestBluetoothPermissions() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'request',
        <String, Object>{'permissions': _bluetoothPermissionKeys},
      );
      return granted ?? false;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Permission request failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'request',
        <String, Object>{'permissions': _cameraPermissionKeys},
      );
      return granted ?? false;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Permission request failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
