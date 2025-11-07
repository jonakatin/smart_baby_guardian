package com.smarttemperatureguard.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val ALARM_CHANNEL = "com.smarttemperatureguard/alarm"
        private const val TORCH_CHANNEL = "com.smarttemperatureguard/torch"
        private const val PERMISSIONS_CHANNEL = "com.smarttemperatureguard/permissions"
        private const val PERMISSION_REQUEST_CODE = 2001
        private const val INITIAL_PERMISSION_REQUEST = 2002
    }

    private var vibrator: Vibrator? = null
    private var cameraManager: CameraManager? = null
    private var torchCameraId: String? = null

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        requestEssentialPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler(this::handleAlarmCall)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TORCH_CHANNEL)
            .setMethodCallHandler(this::handleTorchCall)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler(this::handlePermissionsCall)
    }

    private fun handleAlarmCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVibration" -> {
                startVibration()
                result.success(true)
            }
            "stopVibration" -> {
                stopVibration()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleTorchCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(isTorchAvailable())
            "enable" -> {
                val success = enableTorch()
                result.success(success)
            }
            "disable" -> {
                disableTorch()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun handlePermissionsCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "request") {
            result.notImplemented()
            return
        }
        val keys = call.argument<List<String>>("permissions") ?: emptyList()
        val manifestPermissions = resolvePermissions(keys)
        if (manifestPermissions.isEmpty()) {
            result.success(true)
            return
        }
        val missing = manifestPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("in_progress", "Another permission request is pending", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            missing.toTypedArray(),
            PERMISSION_REQUEST_CODE,
        )
    }

    private fun resolvePermissions(keys: List<String>): Set<String> {
        val permissions = mutableSetOf<String>()
        keys.forEach { key ->
            when (key) {
                "camera" -> permissions.add(Manifest.permission.CAMERA)
                "vibrate" -> permissions.add(Manifest.permission.VIBRATE)
                "bluetooth" -> permissions.add(Manifest.permission.BLUETOOTH)
                "bluetoothScan" -> permissions.add(Manifest.permission.BLUETOOTH_SCAN)
                "bluetoothConnect" -> permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
                "location" -> {
                    permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
                    permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
                }
                "storage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        permissions.add(Manifest.permission.READ_MEDIA_AUDIO)
                    } else {
                        permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
                    }
                }
            }
        }
        return permissions
    }

    private fun requestEssentialPermissions() {
        val essentials = resolvePermissions(
            listOf(
                "camera",
                "vibrate",
                "bluetooth",
                "bluetoothScan",
                "bluetoothConnect",
                "location",
                "storage",
            )
        )
        val missing = essentials.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                missing.toTypedArray(),
                INITIAL_PERMISSION_REQUEST
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun isTorchAvailable(): Boolean {
        val manager = cameraManager ?: return false
        return try {
            resolveTorchCameraId(manager) != null
        } catch (exception: Exception) {
            Log.e(TAG, "Torch availability check failed", exception)
            false
        }
    }

    private fun resolveTorchCameraId(manager: CameraManager): String? {
        if (torchCameraId != null) {
            return torchCameraId
        }
        return try {
            val ids = manager.cameraIdList
            for (id in ids) {
                val characteristics = manager.getCameraCharacteristics(id)
                val hasFlash =
                    characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (hasFlash && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    torchCameraId = id
                    return torchCameraId
                }
            }
            torchCameraId = ids.firstOrNull()
            torchCameraId
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to resolve torch camera", exception)
            null
        }
    }

    private fun enableTorch(): Boolean {
        val manager = cameraManager ?: return false
        val cameraId = resolveTorchCameraId(manager) ?: return false
        return try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                Log.w(TAG, "Camera permission not granted for torch")
                false
            } else {
                manager.setTorchMode(cameraId, true)
                true
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to enable torch", exception)
            false
        }
    }

    private fun disableTorch() {
        val manager = cameraManager ?: return
        val cameraId = resolveTorchCameraId(manager) ?: return
        try {
            manager.setTorchMode(cameraId, false)
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to disable torch", exception)
        }
    }

    private fun startVibration() {
        val vib = vibrator ?: getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        vibrator = vib
        vib ?: return
        try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.VIBRATE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                Log.w(TAG, "Vibration permission not granted")
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vib.vibrate(
                    VibrationEffect.createWaveform(longArrayOf(0, 500, 250, 500), 0)
                )
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(longArrayOf(0, 500, 250, 500), 0)
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to start vibration", exception)
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to stop vibration", exception)
        }
    }
}
