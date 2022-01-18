import org.apache.tools.ant.taskdefs.condition.Os
import java.io.ByteArrayOutputStream
import java.nio.charset.Charset

buildscript {
    repositories {
        jcenter()
        mavenCentral()
    }
    dependencies {
        classpath("org.yaml:snakeyaml:1.17")
    }
}

/**
 * Parsed pubspec.
 */
val pubspec = (org.yaml.snakeyaml.Yaml().load(file("pubspec.yaml").readText()) as Map<String, Any>)

/**
 * Flutter executable
 */
val flutterExe = if (Os.isFamily(Os.FAMILY_WINDOWS)) {
    "flutter.bat"
} else {
    "flutter"
}

/**
 * `protoc` command.
 */
val protocExe = "protoc"

/**
 * /env.yamlから
 */
fun loadFlutterArguments(flavor: String): List<String> {
    if (!rootProject.file("flutter_env.yaml").isFile) {
        return emptyList()
    }
    // parse env.
    val flutterEnv = (org.yaml.snakeyaml.Yaml()
        .load(rootProject.file("flutter_env.yaml").readText()) as Map<String, Any>).let { yaml ->
        (yaml["dart.flutterAdditionalArgs"] as Map<String, Any>)[flavor] as Map<String, Any>
    }

    val flutterArguments = flutterEnv.toList().map { (key, value) ->
        listOf("--dart-define", "$key=$value")
    }.flatten()

    println("flutterArguments=$flutterArguments")

    return flutterArguments
}

task("flutterPubUpgrade") {
    group = "flutter"
    description = "execute `flutter pub upgrade`"
    doLast {
        println("package(${project.name}): $flutterExe pub upgrade")
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf(
                listOf("pub", "upgrade"),
                if(rootProject.properties["flutter.offline"] != null) {
                    listOf("--offline")
                } else {
                    listOf("")
                }
            ).flatten()
        }
    }
}

task("flutterPubOutdated") {
    group = "flutter"
    description = "execute `flutter pub outdated`"
    doLast {
        println("package(${project.name}): $flutterExe pub outdated")
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf("pub", "outdated")
        }
    }
}

task("flutterValidateFormat") {
    group = "flutter"
    description = "validate `flutter format`"
    doLast {
        val skipFormat = setOf(
            "generated_plugin_registrant.dart",
            "generated/intl/",
            "generated/l10n.dart",
            ".g.dart"
        )
        println("package(${project.name}): validate / $flutterExe format file")
        val output = ByteArrayOutputStream()
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf("format", "lib")
            standardOutput = output
        }

        // Support: Flutter 2.5.0 or greater.
        output.toByteArray().toString(Charset.defaultCharset()).also { stdout ->
            if (!stdout.contains("(0 changed)")) {
                println(stdout)
                throw GradleException("Unformatted *.dart")
            }
        }
    }
}

task("flutterFormat") {
    group = "flutter"
    description = "execute `flutter format`"
    doLast {
        println("package(${project.name}): $flutterExe format lib")
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf("format", "lib")
        }
    }
}

task("flutterAnalyze") {
    group = "flutter"
    description = "execute `flutter analyze`"
    doLast {
        println("module(${project.name}): flutter analyze")
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf("analyze")
        }
    }
}

task("flutterTest") {
    group = "flutter"
    description = "execute `flutter test`"
    doLast {
        val testDirectory = File(projectDir, "test")
        val flutterTestDirectory = File(projectDir, "flutter_test")

        if (project.fileTree("test").find { it.extension == "dart" } != null) {
            println("module(${project.name}): flutter test test/")
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf(listOf("test"), loadFlutterArguments("unit_test"), listOf("test/")).flatten()
            }
        }
        if (project.fileTree("flutter_test").find { it.extension == "dart" } != null) {
            println("module(${project.name}): flutter test")
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf(listOf("test"), loadFlutterArguments("unit_test"), listOf("flutter_test/")).flatten()
            }
        }
    }
}

task("flutterCacheClean") {
    group = "flutter"
    description = "delete flutter caches."
    doLast {
        file(".dart_tool").deleteRecursively()
        file("build").deleteRecursively()
        file(".flutter-plugins").delete()
        file(".flutter-plugins-dependencies").delete()
        file(".packages").delete()
        file("pubspec.lock").delete()
    }
}

task("flutterBuildRunner") {
    group = "flutter"
    description = "execute `flutter pub run build_runner build`"
    doLast {
        val dev_dependencies = pubspec["dev_dependencies"] as? Map<String, Any>
        val flutter_intl = pubspec["flutter_intl"] as? Map<String, Any>
        println("dev_dependencies: $dev_dependencies")
        println("flutter_intl: $flutter_intl")
        if (dev_dependencies?.containsKey("build_runner") == true) {
            println("module(${project.name}): flutter pub run build_runner build")
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf("pub", "run", "build_runner", "build", "--delete-conflicting-outputs")
            }
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf("format", "lib")
            }
        }
        if (flutter_intl?.get("enabled") == true) {
            println("module(${project.name}): flutter pub run intl_utils:generate")
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf("pub", "run", "intl_utils:generate")
            }
            exec {
                workingDir = projectDir
                executable = flutterExe
                args = listOf("format", "lib")
            }
        }
    }
}

task("flutterCompileProto3") {
    group = "flutter"
    description = "execute `protoc --dart_out=grpc:lib/src *.proto`"
    doLast {
        fileTree("proto")
            .filter { it.name.endsWith(".proto") }
            .map { it.absoluteFile.normalize() }
            .forEach {
                val proto3path = it.toRelativeString(projectDir)
                val proto3dir = it.parentFile.toRelativeString(projectDir)
                val pathList = (pubspec["proto3"] as? Map<String, Any>)?.let {
                    it["include"] as? List<String>
                }?.map {
                    "-I$it"
                } ?: emptyList()
                println("compile: $proto3path")
                println("pathList: $pathList")
                file("lib/src/proto").mkdirs()
                exec {
                    workingDir = projectDir
                    executable = protocExe
                    args = listOf(
                        listOf("--dart_out=grpc:lib/src/proto"),
                        listOf("-I$proto3dir"),
                        pathList,
                        listOf(proto3path),
                    ).flatten()
                }
            }
        fileTree("lib/src/proto")
            .filter { it.name.endsWith(".dart") }
            .forEach { dart ->
                val replaceList = (pubspec["proto3"] as? Map<String, Any>)?.let {
                    it["replace"] as? List<Map<String, String>>
                } ?: emptyList()

                var converted = dart.readText()
                replaceList.forEach {
                    val from = it["from"]!!.trim()
                    val to = it["to"]!!.trim()
                    println("dart file modify: $from -> $to")
                    converted = converted.replace(from, to)
                }
                dart.writeText(converted)
            }
        exec {
            workingDir = projectDir
            executable = flutterExe
            args = listOf("format", "lib")
        }
    }
}
