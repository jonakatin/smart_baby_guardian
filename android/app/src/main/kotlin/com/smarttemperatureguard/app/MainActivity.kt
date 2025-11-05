package com.smarttemperatureguard.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val PERMISSIONS_CHANNEL = "com.smarttemperatureguard/permissions"
        private const val ALARM_CHANNEL = "com.smarttemperatureguard/alarm"
        private const val TORCH_CHANNEL = "com.smarttemperatureguard/torch"
        private const val REQUEST_CODE_PERMISSIONS = 123
        private const val TORCH_TOGGLE_INTERVAL_MS = 167L
        private val VIBRATION_PATTERN = longArrayOf(0L, 500L, 200L, 500L)
    }

    private val requiredPermissions: Array<String> by lazy {
        val permissions = mutableListOf(
            Manifest.permission.CAMERA,
            Manifest.permission.VIBRATE,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
        } else {
            permissions += Manifest.permission.BLUETOOTH
            permissions += Manifest.permission.BLUETOOTH_ADMIN
        }
        permissions.toTypedArray()
    }

    private var permissionsResult: MethodChannel.Result? = null
    private var autoPermissionRequestActive: Boolean = false
    private var alarmAssetKey: String? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var cameraManager: CameraManager? = null
    private var torchCameraId: String? = null
    private var torchHandler: Handler? = null
    private var torchRunnable: Runnable? = null
    private var torchBlinking: Boolean = false
    private var torchState: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        vibrator = obtainVibrator()
        checkAndRequestPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmAssetKey = try {
            flutterEngine.dartExecutor.assets.lookupKeyForAsset("assets/sounds/high_alarm.wav")
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to resolve alarm asset key", exception)
            null
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "checkAndRequest" -> handlePermissionRequest(result)
                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    Log.e(TAG, "Permission channel failure", exception)
                    result.error("PERMISSION_ERROR", exception.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "playAlarm" -> {
                            if (playAlarm()) {
                                result.success(null)
                            } else {
                                result.error("ALARM_ERROR", "Failed to start alarm", null)
                            }
                        }

                        "stopAlarm" -> {
                            stopAlarm()
                            result.success(null)
                        }

                        "startVibration" -> {
                            if (startVibration()) {
                                result.success(null)
                            } else {
                                result.error("VIBRATION_ERROR", "Vibrator unavailable", null)
                            }
                        }

                        "stopVibration" -> {
                            stopVibration()
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    Log.e(TAG, "Alarm channel failure", exception)
                    result.error("ALARM_ERROR", exception.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TORCH_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "flashOn" -> {
                            if (startTorchBlinking()) {
                                result.success(null)
                            } else {
                                result.error("TORCH_ERROR", "Torch unavailable", null)
                            }
                        }

                        "flashOff" -> {
                            stopTorchBlinking()
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    Log.e(TAG, "Torch channel failure", exception)
                    result.error("TORCH_ERROR", exception.message, null)
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            autoPermissionRequestActive = false
            permissionsResult?.success(granted)
            permissionsResult = null
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun onPause() {
        stopTorchBlinking()
        stopVibration()
        super.onPause()
    }

    override fun onDestroy() {
        stopAlarm()
        releaseMediaPlayer()
        stopVibration()
        stopTorchBlinking()
        super.onDestroy()
    }

    private fun handlePermissionRequest(result: MethodChannel.Result) {
        val missing = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        if (autoPermissionRequestActive || permissionsResult != null) {
            result.error("IN_PROGRESS", "Permission request in progress", null)
            return
        }
        permissionsResult = result
        try {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQUEST_CODE_PERMISSIONS)
        } catch (exception: Exception) {
            permissionsResult = null
            Log.e(TAG, "Failed to request permissions", exception)
            result.error("PERMISSION_ERROR", exception.message, null)
        }
    }

    private fun checkAndRequestPermissions() {
        val missing = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            return
        }
        try {
            autoPermissionRequestActive = true
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQUEST_CODE_PERMISSIONS)
        } catch (exception: Exception) {
            autoPermissionRequestActive = false
            Log.e(TAG, "Automatic permission request failed", exception)
        }
    }

    private fun playAlarm(): Boolean {
        val assetKey = alarmAssetKey ?: return false
        return try {
            assets.openFd(assetKey).use { descriptor ->
                val player = mediaPlayer ?: MediaPlayer().also { mediaPlayer = it }
                player.reset()
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                player.isLooping = true
                player.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                player.prepare()
                player.start()
            }
            true
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to start alarm", exception)
            false
        }
    }

    private fun stopAlarm() {
        val player = mediaPlayer ?: return
        try {
            if (player.isPlaying) {
                player.stop()
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Error stopping alarm", exception)
        }
    }

    private fun releaseMediaPlayer() {
        mediaPlayer?.let { player ->
            try {
                player.reset()
            } catch (exception: Exception) {
                Log.e(TAG, "Failed to reset MediaPlayer", exception)
            }
            try {
                player.release()
            } catch (exception: Exception) {
                Log.e(TAG, "Failed to release MediaPlayer", exception)
            }
        }
        mediaPlayer = null
    }

    private fun startVibration(): Boolean {
        val vib = vibrator ?: obtainVibrator().also { vibrator = it }
        if (vib == null) {
            return false
        }
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(VIBRATION_PATTERN, 0)
                vib.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(VIBRATION_PATTERN, 0)
            }
            true
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to start vibration", exception)
            false
        }
    }

    private fun stopVibration() {
        val vib = vibrator ?: return
        try {
            vib.cancel()
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to stop vibration", exception)
        }
    }

    private fun obtainVibrator(): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                manager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to access vibrator", exception)
            null
        }
    }

    private fun startTorchBlinking(): Boolean {
        if (!isTorchAvailable()) {
            return false
        }
        if (torchBlinking) {
            return true
        }
        val manager = cameraManager ?: return false
        val cameraId = ensureTorchCameraId(manager) ?: return false
        val handler = torchHandler ?: Handler(Looper.getMainLooper()).also { torchHandler = it }
        torchBlinking = true
        torchRunnable = object : Runnable {
            override fun run() {
                if (!torchBlinking) {
                    return
                }
                try {
                    torchState = !torchState
                    manager.setTorchMode(cameraId, torchState)
                    handler.postDelayed(this, TORCH_TOGGLE_INTERVAL_MS)
                } catch (exception: Exception) {
                    Log.e(TAG, "Torch toggle failed", exception)
                    stopTorchBlinking()
                }
            }
        }
        torchRunnable?.let { handler.post(it) }
        return true
    }

    private fun stopTorchBlinking() {
        torchBlinking = false
        torchState = false
        torchRunnable?.let { runnable ->
            torchHandler?.removeCallbacks(runnable)
        }
        torchRunnable = null
        try {
            val manager = cameraManager
            val cameraId = torchCameraId
            if (manager != null && cameraId != null) {
                manager.setTorchMode(cameraId, false)
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to disable torch", exception)
        }
    }

    private fun isTorchAvailable(): Boolean {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) {
            return false
        }
        return cameraManager != null
    }

    private fun ensureTorchCameraId(manager: CameraManager): String? {
        torchCameraId?.let { return it }
        return try {
            for (id in manager.cameraIdList) {
                val characteristics = manager.getCameraCharacteristics(id)
                val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (hasFlash && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    torchCameraId = id
                    return id
                }
                if (hasFlash && torchCameraId == null) {
                    torchCameraId = id
                }
            }
            torchCameraId
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to find torch camera", exception)
            null
        }
    }
}
