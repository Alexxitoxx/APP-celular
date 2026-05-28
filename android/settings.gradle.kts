pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

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

gradle.beforeProject {
    project.afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            // Eliminar atributo package="..." del AndroidManifest.xml si existe (Requerido por AGP 8.0+)
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                try {
                    var content = manifestFile.readText()
                    if (content.contains("package=")) {
                        content = content.replace(Regex("""package="[^"]+""""), "")
                        manifestFile.writeText(content)
                        println("Dynamic Manifest Package Fix Applied for: ${project.name}")
                    }
                } catch (e: Exception) {
                    // Ignorar
                }
            }

            // Corregir incompatibilidad de FlutterMain vs FlutterInjector en Java (Requerido por Flutter 3.0+)
            if (project.name == "tflite_audio") {
                val javaFile = project.file("src/main/java/flutter/tflite_audio/TfliteAudioPlugin.java")
                if (javaFile.exists()) {
                    try {
                        var content = javaFile.readText()
                        if (content.contains("io.flutter.view.FlutterMain")) {
                            content = content.replace("import io.flutter.view.FlutterMain;", "import io.flutter.FlutterInjector;")
                            content = content.replace("FlutterMain.getLookupKeyForAsset(", "FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(")
                            javaFile.writeText(content)
                            println("Dynamic Java Deprecation Fix Applied for tflite_audio!")
                        }
                    } catch (e: Exception) {
                        // Ignorar
                    }
                }
            }

            // Inyectar namespace dinámicamente si no está definido
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    if (getNamespace.invoke(android) == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val namespaceVal = if (project.name == "tflite_audio") "flutter.tflite_audio" else "com.example." + project.name.replace("-", "_").replace(":", "_")
                        setNamespace.invoke(android, namespaceVal)
                        println("Dynamic Namespace Injected in settings: ${project.name} -> $namespaceVal")
                    }
                } catch (e: Exception) {
                    // Ignorar
                }
            }
        }
    }
}
