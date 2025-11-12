plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false

}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Compatibility shim for older Android/Groovy build scripts that still use
// deprecated configurations like `compile`, `testCompile`, `androidTestCompile`.
// Some third-party plugins (e.g., older tflite) call `compile("group:artifact:version")`
// which relies on a configuration named `compile`. Gradle 7+ removed these,
// so we recreate them and make modern configurations extend from them so
// dependencies still land on the classpath.
subprojects {
    // Create legacy configurations if missing
    configurations.maybeCreate("compile")
    configurations.maybeCreate("testCompile")
    configurations.maybeCreate("androidTestCompile")

    fun setupLegacyMappings() {
        configurations.findByName("implementation")?.extendsFrom(configurations.getByName("compile"))
        configurations.findByName("api")?.extendsFrom(configurations.getByName("compile"))
        configurations.findByName("testImplementation")?.extendsFrom(configurations.getByName("testCompile"))
        configurations.findByName("androidTestImplementation")?.extendsFrom(configurations.getByName("androidTestCompile"))
    }

    // Apply after relevant plugins create modern configurations
    pluginManager.withPlugin("com.android.application") { setupLegacyMappings() }
    pluginManager.withPlugin("com.android.library") { setupLegacyMappings() }
    pluginManager.withPlugin("java") { setupLegacyMappings() }
    pluginManager.withPlugin("java-library") { setupLegacyMappings() }
}

// Ensure AGP 8+ namespace is present for certain third-party library modules
subprojects {
    if (name == "tflite_flutter") {
        pluginManager.withPlugin("com.android.library") {
            // Avoid compile-time dependency on AGP types by using reflection
            extensions.findByName("android")?.let { androidExt ->
                try {
                    val m = androidExt.javaClass.methods.firstOrNull { it.name == "setNamespace" && it.parameterTypes.contentEquals(arrayOf(String::class.java)) }
                    m?.invoke(androidExt, "sq.flutter.tflite_flutter")
                } catch (e: Exception) {
                    println("[build.gradle.kts] Could not set namespace for tflite_flutter: ${'$'}{e.message}")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
