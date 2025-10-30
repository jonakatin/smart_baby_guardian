pluginManagement {
    val flutterSdkPath =
        run {
            val localProperties = file("local.properties")
            val envFlutterRoot = System.getenv("FLUTTER_ROOT")
            when {
                localProperties.exists() -> {
                    val properties = java.util.Properties()
                    localProperties.inputStream().use { properties.load(it) }
                    properties.getProperty("flutter.sdk")
                        ?: error("flutter.sdk not set in local.properties")
                }
                !envFlutterRoot.isNullOrBlank() -> envFlutterRoot
                else -> error("Flutter SDK not found. Define it in local.properties or the FLUTTER_ROOT environment variable.")
            }
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    val androidGradlePluginVersion = "8.9.1"
    val kotlinVersion = "2.0.21"

    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version androidGradlePluginVersion apply false
    id("org.jetbrains.kotlin.android") version kotlinVersion apply false
}

include(":app")
