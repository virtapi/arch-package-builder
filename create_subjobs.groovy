def PackagesFile = new File('/var/lib/jenkins/jobs/Arch Package Builder/workspace/aur-packages')
PackagesFile.eachLine { line ->
  packageName = line.trim()
  job("Arch_Package_${packageName}") {
    description("This Job builds the ${packageName} package for archlinux")
    concurrentBuild()
    label('master')
    scm {
      git{
        remote{
          name('origin')
          url("https://aur.archlinux.org/${packageName}.git")
        }
        branch('master')
        extensions {
          cleanBeforeCheckout()
        }
      }
    }
    triggers {
      scm('H/20 * * * *')
    }
    steps {
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
          // add a sync() call, which may prevent broken repo DB
          shell('sync;')
          // remove old release from repodb, add new one
          //shell("/usr/bin/repo-add --remove --quiet /var/www/archlinux/aur/os/x86_64/aur.db.tar.gz /var/www/archlinux/aur/os/x86_64/${packageName}*.pkg.tar.xz")
          // delete the unneded btrfs subvol to free up diskspace
          shell("sudo /usr/bin/btrfs subvolume delete /mnt/aur/build_test/${packageName}")
        }
        onlyIfBuildSucceeds(true)
      }
      // display fancy jokes and a picture of chuck
      chucknorris()
    }
  }
  //queue("Arch_Package_${packageName}")
}
