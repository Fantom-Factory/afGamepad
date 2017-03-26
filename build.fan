using build::BuildPod
using compiler::CompilerInput

class Build : BuildPod {

	new make() {
		podName = "afGamepad"
		summary = "Gamepad controller library"
		version = Version("0.0.4")

		meta = [
			"pod.dis"			: "Gamepad",
			"repo.internal"		: "true",
			"repo.tags"			: "misc, game",
			"repo.public"		: "true"
		]

		depends = [
			"sys        1.0.67 - 1.0",
			
			// ---- Test ------------------------
			"concurrent 1.0.67 - 1.0",
		]

		srcDirs = [`fan/`, `test/`]
		resDirs = [`doc/`]

		docApi	= true
		docSrc	= true
		
		meta["afBuild.testPods"]	= "concurrent"
		meta["afBuild.testDirs"]	= "test/"
	}
	
	override Void onCompileFan(CompilerInput ci) {
		
		// create an uber.jar that contains all the dependent .jar files
		// do it here so F4 doesn't have to
		jarDir := File.createTemp("afGamepad-", "")
		jarDir.delete
		jarDir = Env.cur.tempDir.createDir(jarDir.name).normalize

		echo
		`lib/`.toFile.normalize.listFiles(Regex.glob("*.jar")).each |jar| {
			echo("Expanding ${jar.name} to ${jarDir.osPath}")
			zipIn := Zip.read(jar.in)
			File? entry
			while ((entry = zipIn.readNext) != null) {
				fileOut := jarDir.plus(entry.uri.relTo(`/`))
				entry.copyInto(fileOut.parent, ["overwrite" : true])
			}
			zipIn.close
		}

		jarFile := jarDir.parent.createFile("${jarDir.name}.jar")
		zip  := Zip.write(jarFile.out)
		parentUri := jarDir.uri
		jarDir.walk |src| {
			if (src.isDir) return
			path := src.uri.relTo(parentUri)
			out := zip.writeNext(path)
			src.in.pipe(out)					
			out.close
		}
		zip.close
		
		jarDir.delete

		echo
		echo("Created Uber Jar: ${jarFile.osPath}")
		echo
		
		ci.resFiles.add(jarFile.deleteOnExit.uri)
	}
}

