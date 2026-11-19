pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_ROOT")
                ?: System.getenv("FLUTTER_HOME")
                ?: throw GradleException("flutter.sdk not set in local.properties and FLUTTER_ROOT/FLUTTER_HOME is not defined")
        }

    require(file(flutterSdkPath).exists()) { "Flutter SDK path '$flutterSdkPath' does not exist. Set flutter.sdk in local.properties or FLUTTER_ROOT/FLUTTER_HOME." }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
