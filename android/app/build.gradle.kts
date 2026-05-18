import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ecotrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ecotrack"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

// #region agent log
tasks.configureEach {
    if (name != "mergeDebugResources") return@configureEach
    doFirst {
        try {
            val flutterRoot = rootProject.projectDir.parentFile ?: return@doFirst
            val logFile = File(flutterRoot, "debug-2b2511.log")
            val mergeDir =
                layout.buildDirectory.get().asFile.resolve(
                    "intermediates/incremental/debug/mergeDebugResources",
                )
            val existsBefore = mergeDir.exists()
            val childCountApprox = mergeDir.listFiles()?.size ?: -1
            val bh = mergeDir.absolutePath.hashCode()
            val line =
                """{"sessionId":"2b2511","timestamp":${System.currentTimeMillis()},"hypothesisId":"E","location":"app/build.gradle.kts:mergeDebugResources","message":"task_doFirst","data":{"existsBefore":$existsBefore,"childCountApprox":$childCountApprox,"mergeDirPathHash":$bh}}""" +
                    "\n"
            logFile.appendText(line)
        } catch (_: Exception) {}
    }
}
// #region auto-copy hook
tasks.matching { it.name.startsWith("assemble") }.configureEach {
    doLast {
        try {
            val relocatedBuildDir = rootProject.layout.buildDirectory.get().asFile
            val projectBuildDir = rootProject.projectDir.parentFile.resolve("build")
            
            // Define where the APK is in the relocated folder
            val apkRelPath = "app/outputs/flutter-apk"
            val sourceDir = relocatedBuildDir.resolve(apkRelPath)
            val targetDir = projectBuildDir.resolve(apkRelPath)

            if (sourceDir.exists()) {
                println("[EcoTrack] Syncing APKs to project folder: ${targetDir.absolutePath}")
                targetDir.mkdirs()
                sourceDir.listFiles { f -> f.extension == "apk" }?.forEach { apk ->
                    apk.copyTo(targetDir.resolve(apk.name), overwrite = true)
                }
            }
        } catch (e: Exception) {
            println("[EcoTrack] Failed to sync APK: ${e.message}")
        }
    }
}
// #endregion auto-copy hook
