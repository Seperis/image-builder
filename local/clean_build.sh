#!/bin/bash
# clean up after running build script

# folders
sudo rm -r deploy
sudo rm -r ignore

# files
sudo rm wget*
rm build.log
rm sdcard.log
rm -r configs/custom-debian.conf
rm -r target/chroot/custom-debian.sh
