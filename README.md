# arch-package-builder
Toolbox to create a continuous Delivery Platform with Jenkins-CI for Arch Packages

---

## Contents
+ [Project Description](#project-description)
+ [CD System](#cd-system)
+ [Usage](#usage)
+ [Requirements for self-hosting](#requirements-for-self-hosting)
+ [Issues](#issues)
+ [License](#license)
+ [Contact](#contact)
+ [Contribution](#contribution)


---

## Project Description
We are currently building every AUR package listed in the [aur-packages](aur-packages) file. Our [get-missing-deps.rb](get-missing-deps.rb) script can iterate at the list and find missing dependencies that aren't satisfied by the official repos. This dep will be added to the aur-packages file as well.

---

## CD System
We have got a completely automated continuous delivery pipeline. Every change to the master branch of this repository will notify our [Jenkins-CI](https://ci.virtapi.org). Jenkins runs the [create_subjobs.groovy](create_subjobs.groovy) at every notification. The script creates a job definition for every package. The job will run every 20minutes and deploy the package to our own mirror.

---

## Usage
We provide a normal repository, add the following to your `/etc/pacman.conf`:
```
[aur]
SigLevel = Optional TrustAll
Server = http://mirror.virtapi.org/archlinux/$repo/os/$arch/
```

We also run a modifed version of [Arch Linux Archive](https://wiki.archlinux.org/index.php/Arch_Linux_Archive) which holds all official repositories + our AUR repo, you find it at [http://archive.virtapi.org/](http://archive.virtapi.org/)

## Requirements for self-hosting
### Jenkins Plugins
- [job-dsl](https://plugins.jenkins.io/job-dsl) - create_subjobs.groovy needs it to create jobs from a DSL Script
  You need to approve every change of the create_subjobs.groovy script under *Manage Jenkins > In-process Script Approval*
- [postbuildscript](https://plugins.jenkins.io/postbuildscript) - needed to run post build scripts in DSL
- [ChuckNorris] (https://plugins.jenkins.io/chucknorris) - Errors fears a Round House Kick from ChuckNorris!

### Preperation for mkarchroot
The script works currently with a fix path for the chroot environment, so you have to execute ```mkarchroot /mnt/aur/build_test/root base-devel```

---

## Issues
[Github Issues](https://www.github.com/virtapi/LARS/issues)

---

## License
All of this code is based on the AGPL, you can find the license [here](LICENSE).

--


## Contact
You can meet us in #virtapi at freenode.

---

## Contribution
We've defined our contribution rules in [CONTRIBUTING.md](CONTRIBUTING.md).
