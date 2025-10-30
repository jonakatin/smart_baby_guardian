package com.smartbabyguard.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.smartbabyguard/permissions"
    private val requestCode = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> handlePermissionRequest(call.arguments, result)
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
}
