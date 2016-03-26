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
      shell("sudo /usr/bin/makechrootpkg -u -c -r /mnt/aur/build_test -l ${packageName}")
    }
    publishers {
      artifactDeployer {
        artifactsToDeploy {
          includes('*.pkg.tar.xz')
          remoteFileLocation("/var/www/archlinux/aur/os/x86_64/")
          failIfNoFiles()
          deleteRemoteArtifacts()
        }
      }
      postBuildScripts {
        steps {
          // how to we run this for ever artefact?
          //shell('/usr/bin/repo-add --new --quiet /var/www/archlinux/aur/os/x86_64/repo.db.tar.gz /var/www/archlinux/aur/*.pkg.tar.xz')
          shell("sudo /usr/bin/btrfs subvolume delete /mnt/aur/build_test/${packageName}")
        }
        onlyIfBuildSucceeds(true)
      }
      chucknorris()
    }
  }
  //queue("Arch_Package_${packageName}")
}
