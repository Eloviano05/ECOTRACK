import java.io.File
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter expects all module outputs under PROJECT_ROOT/build. When the repo lives in a synced
// folder (OneDrive/iCloud), Gradle often fails merging resources because the OS/sync layer
// recreates intermediates mid-delete ("Unable to delete directory" / "New files were found").
val flutterProjRoot =
    rootProject.projectDir.parentFile ?: error("android/ must live under Flutter project")

val canonicalWorkspace =
    flutterProjRoot.canonicalPath.replace('\\', '/')
val likelyCloudSyncedWorkspace =
    canonicalWorkspace.contains("onedrive", ignoreCase = true) ||
        canonicalWorkspace.contains("iCloud Drive", ignoreCase = true)

val relocatedBuildRoot: File =
    if (likelyCloudSyncedWorkspace) {
        File(
            System.getenv("LOCALAPPDATA") ?: System.getenv("TEMP")
                ?: System.getProperty("user.home"),
            "EcoTrackGradleBuild/${flutterProjRoot.name}/build",
        ).apply { mkdirs() }
    } else {
        flutterProjRoot.resolve("build")
    }

// #region agent log
run {
    val logFile = File(flutterProjRoot, "debug-2b2511.log")
    val safeBuildRootHash = relocatedBuildRoot.absolutePath.hashCode()
    val line =
        """{"sessionId":"2b2511","timestamp":${System.currentTimeMillis()},"hypothesisId":"A","location":"android/build.gradle.kts","message":"build_dir_resolution","data":{"likelyCloudSyncedWorkspace":$likelyCloudSyncedWorkspace,"redirectActive":$likelyCloudSyncedWorkspace,"effectiveBuildRootPathHash":$safeBuildRootHash}}""" +
            "\n"
    try {
        logFile.appendText(line)
    } catch (_: Exception) {}
}
// #endregion agent log

val newBuildDir: Directory =
    rootProject.objects.directoryProperty().also { dp ->
        dp.set(relocatedBuildRoot)
    }.get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
