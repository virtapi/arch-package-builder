// add a useless comment to trigger a diff to trigger a commit to trigger a PR to trigger a mass rebuild
readFileFromWorkspace('aur-packages').eachLine { line ->
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
      postBuildScripts {
        steps {
          shell('cp "${WORKSPACE}/"*.pkg.tar.* /var/lib/jenkins/packages/')
          shell("/usr/local/bin/copy-and-cleanup ${packageName}");
        }
        onlyIfBuildSucceeds(true)
      }
      // display fancy jokes and a picture of chuck
      chucknorris()
    }
  }
  //queue("Arch_Package_${packageName}")
}
