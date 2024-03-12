plugins {
    java
}

val generateLexers = tasks.create("generateLexers", Exec::class.java) {
    val flexDir = layout.buildDirectory.dir("generated/flex")
    val files = project.provider {
        fileTree("src/main/flex").files.map { it.absolutePath }
    }
    outputs.file(flexDir.get().asFile.resolve("lex.yy.c"))
    doFirst {
        flexDir.get().asFile.mkdirs()
        commandLine("flex", "-l", "-o", flexDir.get().asFile.resolve("lex.yy.c").absolutePath, *files.get().toTypedArray())
    }
}

val compileLexers = tasks.create("compileLexers", Exec::class.java) {
    val compiledDir = layout.buildDirectory.dir("compiled")
    dependsOn(generateLexers)
    outputs.file(compiledDir.get().asFile.resolve("lexer.o"))
    doFirst {
        compiledDir.get().asFile.mkdirs()
        commandLine("gcc", "-o", compiledDir.get().asFile.resolve("lexer.o").absolutePath, generateLexers.outputs.files.singleFile.absolutePath, "-lfl")
    }
}

val buildSharedLibrary = tasks.create("buildSharedLibrary", Exec::class.java) {
    val JAVA_HOME = System.getenv("JAVA_HOME")
    val compiledDir = layout.buildDirectory.dir("compiled")
    val outputFile = compiledDir.get().asFile.resolve("dev_rvr_lexerlearning_lexer_Lexer.o").absolutePath
    outputs.file(outputFile)
    dependsOn(compileLexers)
    doFirst {
        commandLine(
            "g++",
            "-c",
            "-fPIC",
            "-I${JAVA_HOME}/include",
            "-I${JAVA_HOME}/include/linux",
            "src/main/app/dev_rvr_lexerlearning_lexer_Lexer.c",
            "-o",
            outputFile
        )
    }
}

val linkSharedLibrary = tasks.create("linkSharedLibrary", Exec::class.java) {
    val sharedLibDir = layout.buildDirectory.dir("lib/shared")
    dependsOn(buildSharedLibrary)
    val libnative = sharedLibDir.get().asFile.resolve("libnative.so")
    outputs.file(libnative)
    doFirst {
        sharedLibDir.get().asFile.mkdirs()
        commandLine(
            "g++",
            "-shared",
            "-fPIC",
            "-o",
            libnative.absolutePath,
            buildSharedLibrary.outputs.files.singleFile.absolutePath,
//            compileLexers.outputs.files.singleFile.absolutePath,
            "-lc"
        )
    }
}

val run = tasks.create("run", JavaExec::class.java) {
    dependsOn(linkSharedLibrary, "assemble")
    classpath = files("build/classes/java/main/dev/rvr/lexerlearning/lexer/Lexer")
    args = listOf("-Djava.library.path="+linkSharedLibrary.outputs.files.singleFile.absolutePath)
}

version = "1.2.1"