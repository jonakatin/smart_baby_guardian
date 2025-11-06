package com.smarttemperatureguard.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val METHOD_CHANNEL = "com.smarttemperatureguard/alarm"
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val ALARM_ASSET_PATH = "assets/sounds/high_alarm.wav"
    }

    private var alarmAssetKey: String? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var cameraId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        requestAllPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmAssetKey = try {
            val loader = FlutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            loader.getLookupKeyForAsset(ALARM_ASSET_PATH)
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to resolve alarm asset key", exception)
            null
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "triggerAlarm" -> {
                        playAlarm()
                        vibratePattern()
                        toggleFlashlight(true)
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        stopAlarm()
                        stopVibration()
                        toggleFlashlight(false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onPause() {
        super.onPause()
        stopAlarm()
        stopVibration()
        toggleFlashlight(false)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        stopVibration()
        toggleFlashlight(false)
    }

    private fun requestAllPermissions() {
        val permissions = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.VIBRATE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                missing.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun playAlarm() {
        if (mediaPlayer?.isPlaying == true) {
            return
        }
        stopAlarm()
        val assetKey = alarmAssetKey ?: return
        try {
            applicationContext.assets.openFd(assetKey).use { afd ->
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    isLooping = true
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    prepare()
                    start()
                }
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Error playing alarm", exception)
        }
    }

    private fun stopAlarm() {
        mediaPlayer?.apply {
            try {
                if (isPlaying) {
                    stop()
                }
            } catch (exception: Exception) {
                Log.e(TAG, "Error stopping alarm", exception)
            }
            try {
                release()
            } catch (exception: Exception) {
                Log.e(TAG, "Error releasing MediaPlayer", exception)
            }
        }
        mediaPlayer = null
    }

    private fun vibratePattern() {
        val vib = vibrator ?: getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        vibrator = vib
        vib ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vib.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 400, 200, 400), 0))
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(longArrayOf(0, 400, 200, 400), 0)
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Error starting vibration", exception)
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (exception: Exception) {
            Log.e(TAG, "Error stopping vibration", exception)
        }
    }

    private fun toggleFlashlight(on: Boolean) {
        val manager = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return
        if (cameraId == null) {
            cameraId = manager.cameraIdList.firstOrNull()
        }
        val id = cameraId ?: return
        try {
            manager.setTorchMode(id, on)
        } catch (exception: Exception) {
            Log.e(TAG, "Flashlight error", exception)
        }
    }
}
