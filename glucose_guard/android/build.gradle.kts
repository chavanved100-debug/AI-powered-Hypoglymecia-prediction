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
    
    // Ensure consistent JVM target for all Kotlin modules
    if (project.plugins.hasPlugin("org.jetbrains.kotlin.android") || 
        project.plugins.hasPlugin("org.jetbrains.kotlin.jvm")) {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    
    if (project.plugins.hasPlugin("com.android.library") || 
        project.plugins.hasPlugin("com.android.application")) {
        tasks.withType<org.gradle.api.tasks.compile.JavaCompile> {
            options.release.set(17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
