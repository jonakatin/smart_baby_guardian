import com.android.build.gradle.LibraryExtension
plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0"
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    evaluationDependsOn(":app")
}

gradle.beforeProject {
    if (name == "flutter_bluetooth_serial") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                namespace = "io.github.edufolly.flutterbluetoothserial"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
