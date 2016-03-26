# arch-package-builder
Toolbox to create a continuous Delivery Platform with Jenkins-CI for Arch Packages

---

## Contents
+ [Project Description](#project-description)
+ [CD System](#cd-system)
+ [Usage](#usage)

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
