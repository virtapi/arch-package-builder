#!/bin/bash

##
# written by bastelfreak
##
# this script creates the initial db for our repo
# you can rerun this after every change to the repo, but thats slow
##

cd /var/www/archlinux/aur/os/x86_64 || exit
find . -type f -name "*.pkg.tar.xz" -exec repo-add --new aur.db.tar.gz {} \;
chown jenkins:jenkins aur.db*
chown jenkins:jenkins aur.files*
