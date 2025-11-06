import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var alarmPlayer: AVAudioPlayer?
  private var alarmAssetPath: String?
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
      name: "com.smartbabyguard/alarm",
      binaryMessenger: messenger
    )
    alarmChannel.setMethodCallHandler(handleAlarm)

    let torchChannel = FlutterMethodChannel(
      name: "com.smartbabyguard/torch",
      binaryMessenger: messenger
    )
    torchChannel.setMethodCallHandler(handleTorch)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleAlarm(call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "initialize":
      guard
        let arguments = call.arguments as? [String: Any],
        let asset = arguments["asset"] as? String,
        let path = assetPath(for: asset)
      else {
        result(FlutterError(code: "ARG_ERROR", message: "Alarm asset path is required.", details: nil))
        return
      }
      alarmAssetPath = path
      resetAlarmPlayer()
      result(nil)

    case "start":
      let arguments = call.arguments as? [String: Any]
      if let asset = arguments?["asset"] as? String {
        alarmAssetPath = assetPath(for: asset) ?? alarmAssetPath
      }
      let volume = Float((arguments?["volume"] as? NSNumber)?.doubleValue ?? 1.0)
      if startAlarm(volume: volume) {
        result(nil)
      } else {
        result(FlutterError(code: "ALARM_ERROR", message: "Unable to start alarm playback.", details: nil))
      }

    case "setVolume":
      let arguments = call.arguments as? [String: Any]
      let volume = Float((arguments?["volume"] as? NSNumber)?.doubleValue ?? 1.0)
      setAlarmVolume(volume)
      result(nil)

    case "stop":
      stopAlarm()
      result(nil)

    case "dispose":
      disposeAlarm()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleTorch(call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
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

  private func assetPath(for asset: String) -> String? {
    let key = FlutterDartProject.lookupKey(forAsset: asset)
    return Bundle.main.path(forResource: key, ofType: nil)
  }

  private func startAlarm(volume: Float) -> Bool {
    guard let path = alarmAssetPath ?? assetPath(for: "sounds/high_alarm.mp3") else {
      return false
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, options: [.duckOthers])
      try session.setActive(true)

      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.numberOfLoops = -1
      player.volume = max(0, min(volume, 1))
      player.prepareToPlay()
      player.play()
      alarmPlayer = player
      return true
    } catch {
      return false
    }
  }

  private func setAlarmVolume(_ volume: Float) {
    alarmPlayer?.volume = max(0, min(volume, 1))
  }

  private func stopAlarm() {
    alarmPlayer?.stop()
    alarmPlayer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  private func resetAlarmPlayer() {
    alarmPlayer?.stop()
    alarmPlayer = nil
  }

  private func disposeAlarm() {
    stopAlarm()
  }

  private func isTorchAvailable() -> Bool {
    return resolveTorchDevice() != nil
  }

  private func resolveTorchDevice() -> AVCaptureDevice? {
    if let device = cachedTorchDevice, device.hasTorch {
      return device
    }

    if let defaultDevice = AVCaptureDevice.default(for: .video), defaultDevice.hasTorch {
      cachedTorchDevice = defaultDevice
      return defaultDevice
    }

    if #available(iOS 10.0, *) {
      let discovery = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
          .builtInWideAngleCamera,
          .builtInDualCamera,
          .builtInDualWideCamera,
          .builtInTelephotoCamera,
          .builtInTrueDepthCamera,
          .builtInUltraWideCamera
        ],
        mediaType: .video,
        position: .unspecified
      )
      if let device = discovery.devices.first(where: { $0.hasTorch }) {
        cachedTorchDevice = device
        return device
      }
    } else {
      for device in AVCaptureDevice.devices(for: .video) where device.hasTorch {
        cachedTorchDevice = device
        return device
      }
    }

    return nil
  }

  private func updateTorch(enabled: Bool) -> Bool {
    guard let device = resolveTorchDevice(), device.hasTorch else {
      return false
    }
    do {
      try device.lockForConfiguration()
    } catch {
      cachedTorchDevice = nil
      return false
    }

    defer { device.unlockForConfiguration() }

    if enabled {
      guard device.isTorchModeSupported(.on) else {
        return false
      }
      let level = min(device.maxAvailableTorchLevel, 1.0)
      do {
        try device.setTorchModeOn(level: level)
      } catch {
        cachedTorchDevice = nil
        return false
      }
    } else if device.isTorchModeSupported(.off) {
      device.torchMode = .off
    }
    return true
  }
}
