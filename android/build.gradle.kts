allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// O repositório vive dentro de uma pasta sincronizada pelo OneDrive. Somado
// aos caminhos profundos que o Android Gradle Plugin gera em
// build/.transforms/.../, o total ultrapassa o limite de 260 caracteres do
// Windows e quebra o build (arquivos "somem" no meio da compilação). Se
// `custom.buildDir` estiver definido no local.properties (não versionado,
// específico da máquina), usamos um caminho curto fora do OneDrive.
val localProperties = java.util.Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val customBuildDir = localProperties.getProperty("custom.buildDir")

val newBuildDir: Directory = if (customBuildDir != null) {
    rootProject.layout.projectDirectory.dir(customBuildDir.replace("\\", "/"))
} else {
    rootProject.layout.buildDirectory.dir("../../build").get()
}
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
