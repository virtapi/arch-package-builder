def PackagesFile = new File('/var/lib/jenkins/jobs/Arch Package Builder/workspace/aur-packages')
PackagesFile.eachLine { line ->
  packageName = line.trim()
  job("Arch_Package_${packageName}") {
    description("This Job builds the ${packageName} package for archlinux")
    concurrentBuild()
    label('master')
    scm {
      git("https://aur.archlinux.org/${packageName}.git")
    }
    triggers {
      scm('H/20 * * * *')
    }
    steps {
      // updates are fine, but there is currently no working locking
      //shell("sudo /usr/bin/arch-nspawn /mnt/aur/build_test/root pacman -Syyu; sudo /usr/bin/makechrootpkg -c -r /mnt/aur/build_test -l ${packageName}")
      shell("sudo /usr/bin/makechrootpkg -c -r /mnt/aur/build_test -l ${packageName}")
      def folder = new File("/var/www/archlinux/${packageName}/")
      if( !folder.exists() ) {
        folder.mkdirs()
      }
      artifactDeployer {
        includes('*.pkg.tar.xz')
        remoteFileLocation("/var/www/archlinux/aur/")
        failIfNoFiles()
        deleteRemoteArtifacts()
      }
    }
  }
  queue("Arch_Package_${packageName}")
}
