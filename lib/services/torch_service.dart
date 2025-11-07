import 'package:flutter/services.dart';

class TorchService {
  TorchService._();

  static final TorchService instance = TorchService._();

  static const MethodChannel _channel =
      MethodChannel('com.smarttemperatureguard/torch');
  bool? _isAvailable;

  Future<bool> isTorchAvailable() async {
    if (_isAvailable != null) {
      return _isAvailable!;
    }
    try {
      final bool? available = await _channel.invokeMethod<bool>('isAvailable');
      _isAvailable = available ?? false;
    } on PlatformException {
      _isAvailable = false;
    }
    return _isAvailable!;
  }

  Future<void> enableTorch() async {
    if (!await isTorchAvailable()) {
      return;
    }
    try {
      await _channel.invokeMethod('enable');
    } on PlatformException {
      _isAvailable = null;
    }
  }

  Future<void> disableTorch() async {
    if (_isAvailable == false) {
      return;
    }
    try {
      await _channel.invokeMethod('disable');
    } on PlatformException {
      _isAvailable = null;
    }
  }
}
