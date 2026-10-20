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
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // Disable redundant library resource verification that causes AAPT2 daemon IPC timeouts on Windows
    tasks.configureEach {
        if (name.startsWith("verify") && name.endsWith("Resources")) {
            enabled = false
        }
    }
}

subprojects {
    plugins.withId("com.android.library") {
        dependencies {
            add("compileOnly", "androidx.concurrent:concurrent-futures:1.2.0")
            add("compileOnly", "androidx.concurrent:concurrent-futures-ktx:1.2.0")
            add("compileOnly", "org.jspecify:jspecify:1.0.0")
        }
    }
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.2.0")
            force("androidx.concurrent:concurrent-futures-ktx:1.2.0")
            force("org.jspecify:jspecify:1.0.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
