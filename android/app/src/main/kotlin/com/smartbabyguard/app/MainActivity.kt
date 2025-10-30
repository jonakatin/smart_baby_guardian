package com.smartbabyguard.app

import android.Manifest
import android.content.pm.PackageManager
import android.content.res.AssetFileDescriptor
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.MediaPlayer
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val permissionChannelName = "com.smartbabyguard/permissions"
    private val alarmChannelName = "com.smartbabyguard/alarm"
    private val torchChannelName = "com.smartbabyguard/torch"
    private val requestCode = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var alarmAssetPath: String? = null
    private var mediaPlayer: MediaPlayer? = null
    private var torchCameraId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupPermissionChannel(flutterEngine)
        setupAlarmChannel(flutterEngine)
        setupTorchChannel(flutterEngine)
    }

    override fun onDestroy() {
        disposeAlarm()
        disableTorchInternal()
        super.onDestroy()
    }

    private fun setupPermissionChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> handlePermissionRequest(call.arguments, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupAlarmChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        alarmAssetPath = call.argument("asset")
                        result.success(true)
                    }

                    "start" -> {
                        val asset = call.argument<String>("asset") ?: alarmAssetPath
                        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        if (asset == null) {
                            result.error("ASSET_MISSING", "No alarm asset provided.", null)
                        } else if (playAlarm(asset, volume)) {
                            result.success(true)
                        } else {
                            result.error("ALARM_ERROR", "Unable to play alarm asset.", null)
                        }
                    }

                    "setVolume" -> {
                        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        setAlarmVolume(volume)
                        result.success(true)
                    }

                    "stop" -> {
                        stopAlarm()
                        result.success(true)
                    }

                    "dispose" -> {
                        disposeAlarm()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun setupTorchChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, torchChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTorchAvailable" -> result.success(isTorchAvailableInternal())

                    "enable" -> {
                        if (enableTorchInternal()) {
                            result.success(true)
                        } else {
                            result.error("TORCH_ERROR", "Torch not available", null)
                        }
                    }

                    "disable" -> {
                        disableTorchInternal()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun handlePermissionRequest(arguments: Any?, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("IN_PROGRESS", "A permission request is already running.", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val codes = (arguments as? Map<String, Any?>)?.get("permissions") as? List<*>
        val requestedPermissions = permissionsFor(codes)
            .filter { permission ->
                ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED
            }
            .distinct()

        if (requestedPermissions.isEmpty()) {
            result.success(true)
            return
        }

        pendingResult = result
        ActivityCompat.requestPermissions(
            this,
            requestedPermissions.toTypedArray(),
            requestCode
        )
    }

    private fun permissionsFor(rawCodes: List<*>?): List<String> {
        if (rawCodes == null) {
            return emptyList()
        }
        val permissions = mutableListOf<String>()
        for (code in rawCodes) {
            when (code as? String) {
                "bluetooth" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                        permissions += Manifest.permission.BLUETOOTH
                        permissions += Manifest.permission.BLUETOOTH_ADMIN
                    }
                }

                "bluetoothScan" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        permissions += Manifest.permission.BLUETOOTH_SCAN
                    } else {
                        permissions += Manifest.permission.ACCESS_FINE_LOCATION
                        permissions += Manifest.permission.ACCESS_COARSE_LOCATION
                    }
                }

                "bluetoothConnect" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        permissions += Manifest.permission.BLUETOOTH_CONNECT
                    }
                }

                "locationWhenInUse" -> {
                    permissions += Manifest.permission.ACCESS_FINE_LOCATION
                    permissions += Manifest.permission.ACCESS_COARSE_LOCATION
                }

                "camera" -> {
                    permissions += Manifest.permission.CAMERA
                }
            }
        }
        return permissions
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == this.requestCode) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(granted)
            pendingResult = null
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    private fun playAlarm(asset: String, volume: Float): Boolean {
        return try {
            val loader = FlutterInjector.instance().flutterLoader()
            val lookupKey = loader.getLookupKeyForAsset(asset)
            val descriptor: AssetFileDescriptor = applicationContext.assets.openFd(lookupKey)
            val player = MediaPlayer()
            player.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
            descriptor.close()
            val clamped = volume.coerceIn(0f, 1f)
            player.isLooping = true
            player.setVolume(clamped, clamped)
            player.prepare()
            player.start()
            mediaPlayer?.release()
            mediaPlayer = player
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun setAlarmVolume(volume: Float) {
        val clamped = volume.coerceIn(0f, 1f)
        mediaPlayer?.setVolume(clamped, clamped)
    }

    private fun stopAlarm() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.reset()
                it.release()
            }
        } catch (_: Exception) {
        } finally {
            mediaPlayer = null
        }
    }

    private fun disposeAlarm() {
        stopAlarm()
    }

    private fun isTorchAvailableInternal(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }
        val manager = getSystemService(CAMERA_SERVICE) as? CameraManager ?: return false
        return try {
            manager.cameraIdList.any { id ->
                val characteristics = manager.getCameraCharacteristics(id)
                val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (hasFlash && lensFacing == CameraCharacteristics.LENS_FACING_BACK) {
                    torchCameraId = id
                    true
                } else {
                    false
                }
            }
        } catch (_: CameraAccessException) {
            false
        }
    }

    private fun enableTorchInternal(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }
        val manager = getSystemService(CAMERA_SERVICE) as? CameraManager ?: return false
        val cameraId = ensureTorchCameraId(manager) ?: return false
        return try {
            manager.setTorchMode(cameraId, true)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun disableTorchInternal(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }
        val manager = getSystemService(CAMERA_SERVICE) as? CameraManager ?: return false
        val cameraId = ensureTorchCameraId(manager) ?: return false
        return try {
            manager.setTorchMode(cameraId, false)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun ensureTorchCameraId(manager: CameraManager): String? {
        torchCameraId?.let { return it }
        return try {
            val id = manager.cameraIdList.firstOrNull { cameraId ->
                val characteristics = manager.getCameraCharacteristics(cameraId)
                val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
                hasFlash && lensFacing == CameraCharacteristics.LENS_FACING_BACK
            }
            torchCameraId = id
            id
        } catch (_: CameraAccessException) {
            null
        }
    }
}
