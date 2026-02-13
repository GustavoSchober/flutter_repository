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
    afterEvaluate {
        // Procura se o subprojeto tem o plugin 'android' (se é um app ou plugin Flutter)
        val android = extensions.findByName("android")
        if (android != null) {
            // Força o compileSdkVersion para 35 usando reflexão (para evitar erros de tipo no Kotlin)
            val compileSdkVersionMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
            compileSdkVersionMethod.invoke(android, 35)

            // Correção extra: Se o plugin for muito velho e não tiver 'namespace' definido (exige no Android novo)
            // nós definimos um namespace padrão para ele não quebrar o build.
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)

                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, project.group.toString())
                }
            } catch (e: Exception) {
                // Se der erro nessa parte do namespace, segue o jogo (pode ser versão antiga do Gradle)
            }
        }
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}