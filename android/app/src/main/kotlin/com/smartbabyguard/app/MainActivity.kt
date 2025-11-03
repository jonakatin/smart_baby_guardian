package com.smartbabyguard.app

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.smartbabyguard/permissions"
    private val alarmChannelName = "com.smartbabyguard/alarm"
    private val requestCode = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var mediaPlayer: MediaPlayer? = null
    private var alarmAssetPath: String? = null
    private var assetLookup: ((String) -> String)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        assetLookup = { asset ->
            flutterEngine.dartExecutor.flutterAssets.getAssetFilePathByName(asset)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> handlePermissionRequest(call.arguments, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val asset = call.argument<String>("asset")
                        if (asset.isNullOrEmpty()) {
                            result.error("ARG_ERROR", "Alarm asset path is required.", null)
                            return@setMethodCallHandler
                        }
                        alarmAssetPath = assetLookup?.invoke(asset)
                        resetMediaPlayer()
                        result.success(null)
                    }

                    "start" -> {
                        val volume = (call.argument<Number>("volume")?.toFloat() ?: 1f)
                            .coerceIn(0f, 1f)
                        if (startAlarm(volume)) {
                            result.success(null)
                        } else {
                            result.error(
                                "ALARM_ERROR",
                                "Unable to start alarm playback.",
                                null
                            )
                        }
                    }

                    "setVolume" -> {
                        val volume = (call.argument<Number>("volume")?.toFloat() ?: 1f)
                            .coerceIn(0f, 1f)
                        setAlarmVolume(volume)
                        result.success(null)
                    }

                    "stop" -> {
                        stopAlarm()
                        result.success(null)
                    }

                    "dispose" -> {
                        disposeAlarm()
                        result.success(null)
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

    private fun startAlarm(volume: Float): Boolean {
        val assetPath = alarmAssetPath
            ?: assetLookup?.invoke("sounds/high_alarm.wav")
            ?: return false
        return try {
            applicationContext.assets.openFd(assetPath).use { afd ->
                val player = mediaPlayer ?: MediaPlayer().also { mediaPlayer = it }
                player.reset()
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                player.isLooping = true
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                player.prepare()
                player.setVolume(volume, volume)
                player.start()
            }
            true
        } catch (exception: Exception) {
            false
        }
    }

    private fun setAlarmVolume(volume: Float) {
        try {
            mediaPlayer?.setVolume(volume, volume)
        } catch (_: IllegalStateException) {
            // Ignore attempts to set the volume when the player is not ready.
        }
    }

    private fun stopAlarm() {
        val player = mediaPlayer ?: return
        try {
            if (player.isPlaying) {
                player.stop()
            }
        } catch (_: IllegalStateException) {
        } finally {
            try {
                player.reset()
            } catch (_: IllegalStateException) {
            }
        }
    }

    private fun resetMediaPlayer() {
        mediaPlayer?.let {
            try {
                if (it.isPlaying) {
                    it.stop()
                }
            } catch (_: IllegalStateException) {
            }
            try {
                it.reset()
            } catch (_: IllegalStateException) {
            }
        }
    }

    private fun disposeAlarm() {
        mediaPlayer?.let {
            try {
                if (it.isPlaying) {
                    it.stop()
                }
            } catch (_: IllegalStateException) {
            }
            try {
                it.release()
            } catch (_: IllegalStateException) {
            }
        }
        mediaPlayer = null
    }

    override fun onDestroy() {
        disposeAlarm()
        super.onDestroy()
    }
}
