// Compatibility init script to support older plugins using `compile` configuration
// Gradle Kotlin DSL init scripts run during initialization and can add methods to projects

allprojects {
    // Add an extension function named `compile` that proxies to `implementation` to
    // provide backward compatibility for older plugin build scripts that still call
    // `compile("...")` which was removed in Gradle 7/8.
    
    extensions.extraProperties.set("compatibilityCompileAdded", true)

    afterEvaluate {
        try {
            // Only attempt registration if method doesn't exist
            val hasCompile = try {
                // This will throw if the method doesn't exist in the dependencies DSL
                dependencies::class.java.getMethod("compile", Any::class.java)
                true
            } catch (e: NoSuchMethodException) {
                false
            }

            if (!hasCompile) {
                // Use reflection to add a proxy method 'compile' to the project's dependencies handler
                val depHandler = dependencies
                val implMethod = depHandler::class.java.getMethod("implementation", Any::class.java)

                val proxy = java.lang.reflect.Proxy.newProxyInstance(
                    depHandler::class.java.classLoader,
                    arrayOf(Class.forName("org.gradle.api.artifacts.dsl.DependencyHandler"))
                ) { _, method, args ->
                    if (method.name == "compile") {
                        implMethod.invoke(depHandler, *args)
                        null
                    } else {
                        method.invoke(depHandler, *args)
                    }
                }

                // Replace project.dependencies with the proxy
                val field = project::class.java.getDeclaredField("dependencies")
                field.isAccessible = true
                field.set(project, proxy)
            }
        } catch (e: Exception) {
            // Don't fail the build if the compatibility layer can't be installed; just log
            println("[init.gradle.kts] Could not install compile->implementation compatibility: ${'$'}{e.message}")
        }
    }
}
