import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.smarttemperatureguard/permissions');

  static Future<bool> requestBluetoothPermissions() async {
    return _request(<String>[
      'bluetooth',
      'bluetoothScan',
      'bluetoothConnect',
      'location',
    ]);
  }

  static Future<bool> requestCameraPermission() async {
    return _request(const <String>['camera']);
  }

  static Future<bool> requestVibrationPermission() async {
    return _request(const <String>['vibrate']);
  }

  static Future<bool> requestStoragePermission() async {
    return _request(const <String>['storage']);
  }

  static Future<void> ensureEssentialPermissions() async {
    await requestBluetoothPermissions();
    await requestStoragePermission();
    await requestVibrationPermission();
    await requestCameraPermission();
  }

  static Future<bool> _request(List<String> permissions) async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'request',
        <String, Object>{'permissions': permissions},
      );
      return granted ?? false;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Permission request failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
