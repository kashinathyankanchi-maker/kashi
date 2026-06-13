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
    fun configureProject() {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            try {
                val method = androidExtension.javaClass.getMethod("compileSdkVersion", Integer.TYPE)
                method.invoke(androidExtension, 36)
            } catch (e: Exception) {
                logger.warn("Could not set compileSdkVersion on project ${name} dynamically: ${e.message}")
            }
        }
    }

    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
