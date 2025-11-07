import AudioToolbox
import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var vibrationTimer: Timer?
  private var cachedTorchDevice: AVCaptureDevice?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let messenger = controller.binaryMessenger

    let alarmChannel = FlutterMethodChannel(
      name: "com.smarttemperatureguard/alarm",
      binaryMessenger: messenger
    )
    alarmChannel.setMethodCallHandler(handleAlarm)

    let torchChannel = FlutterMethodChannel(
      name: "com.smarttemperatureguard/torch",
      binaryMessenger: messenger
    )
    torchChannel.setMethodCallHandler(handleTorch)

    let permissionsChannel = FlutterMethodChannel(
      name: "com.smarttemperatureguard/permissions",
      binaryMessenger: messenger
    )
    permissionsChannel.setMethodCallHandler { call, result in
      if call.method == "request" {
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleAlarm(call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "startVibration":
      startVibration()
      result(nil)

    case "stopVibration":
      stopVibration()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleTorch(call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(isTorchAvailable())

    case "isTorchAvailable":
      result(isTorchAvailable())

    case "enable":
      if updateTorch(enabled: true) {
        result(nil)
      } else {
        result(FlutterError(code: "TORCH_ERROR", message: "Unable to enable the torch.", details: nil))
      }

    case "disable":
      if updateTorch(enabled: false) {
        result(nil)
      } else {
        result(FlutterError(code: "TORCH_ERROR", message: "Unable to disable the torch.", details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startVibration() {
    stopVibration()
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
  }

  private func stopVibration() {
    vibrationTimer?.invalidate()
    vibrationTimer = nil
  }

  private func isTorchAvailable() -> Bool {
    if let device = cachedTorchDevice {
      return device.hasTorch
    }
    guard let device = AVCaptureDevice.default(for: .video) else {
      return false
    }
    cachedTorchDevice = device
    return device.hasTorch
  }

  private func updateTorch(enabled: Bool) -> Bool {
    guard let device = cachedTorchDevice ?? AVCaptureDevice.default(for: .video) else {
      return false
    }
    cachedTorchDevice = device
    guard device.hasTorch else { return false }
    do {
      try device.lockForConfiguration()
      device.torchMode = enabled ? .on : .off
      device.unlockForConfiguration()
      return true
    } catch {
      return false
    }
  }
}
