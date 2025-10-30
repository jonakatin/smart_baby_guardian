pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val flutterSdkPath: String? = System.getenv("FLUTTER_ROOT")
        ?: java.io.File(settingsDir, "local.properties")
            .takeIf { it.exists() }
            ?.readLines()
            ?.find { it.startsWith("flutter.sdk=") }
            ?.substringAfter("=")
            ?.trim()

    if (flutterSdkPath == null) {
        throw GradleException("❌ Flutter SDK not found. Please set flutter.sdk in local.properties.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

include(":app")

plugins {
    val androidGradlePluginVersion = "8.9.1"
    val kotlinVersion = "2.0.21"

    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version androidGradlePluginVersion apply false
    id("org.jetbrains.kotlin.android") version kotlinVersion apply false
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}
