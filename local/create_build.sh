#!/bin/bash

#passed variable 
x=$1

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=/$PROJ/beagle_play
bb_home=/$PROJ/bb_black 
img_home=/$PROJ/seperis-image-builder

# options
# architecture options: armhf arm64
# os version: console iot minimal xfce
# os name: debian ubuntu

# os name
os_name="debian"

# variables
time=$(date +%Y-%m-%d)
datestamp=$(date +%Y%m%d%T)

# build file
mybuild="arm64_xfce_bkwm_12.4_v6.1ti_play"

# build variables
board_arch=( cut -d "_" -f1 >>> $mybuild )
os_version=( cut -d "_" -f2 >>> $mybuild )
os_codeac=( cut -d "_" -f3 >>> $mybuild )
os_rel=( cut -d "_" -f4 >>> $mybuild )
kern_ver=( cut -d "_" -f5 >>> $mybuild )
board_ac=( cut -d "_" -f6 >>> $mybuild )

# os codename
if [ "$os_codeac" = "bkwm" ]; then
	os_codename="Bookworm"
fi

# copy sh folder to target
if [ $board_arch = "armhf" ]; then
	cp local/armhf_bkwm_custom-debian.sh target/chroot/custom-debian.sh

# deploy
# variables
# build name
# format: [operating system]-[release number]-[os type]-[board architecture]-[date]
dep_name="$os_name-$os_rel-$os_type-$board_arch-$time"
# build version
build_ver="bv1-dev"
# image name
# format: [ board_ac-os_codename-os_rel-os_type-kern_ver-date-build_ver
img_name="$board_ac-$os_codename-$os_rel-$os_type-$kern_ver-$date-$build_ver"
img_ext=".img" 
# log
log="${OIB_DIR}/sdcard.log"
# tags
# size_tag_options:--img-1gb --img-2gb --img-4gb --img-6gb --img-8gb --img-10gb
play_tags="--dtb beagleplay --boot_label BEAGLEPLAY --rootfs_label PLAY --hostname circe"
bbb_tags="--dtb beaglebone --boot_label BEAGLEBONE --rootfs_label BONE --hostname medusa --enable-cape-universal"

# board name
if [ $board_ac = "play" ]; then
  board_name="Beagle Play"
  board_fldr="$play_home"
  opt_tags="$play_tags"
elif [ $board_ac = "bone" ]; then
  board_name="BeagleBone Black"
  board_fldr="$bb_home"
  opt_tags="$bbb_tags"
else
  echo "no idea"
fi

# iot
if [ $os_ver = "iot" ]; then
	size_tag="--img-4gb"
elif [ $os_ver = "minimal" ]; then
	if [ $board_arch = "armf" ]; then
		size_tag="--img-2gb"
	else
		size_tag="--img-6gb"
	fi
elif [ $os_ver = "xfce" ]; then
	size_tag="--img-10gb"
fi

# log
log="${OIB_DIR}/sdcard.log"

# sd
/bin/bash -e "${OIB_DIR}/deploy/$dep_name/setup_sdcard.sh $size_tag $img_name $opt_tags 2>&1 | tee $log" 

# compression
my_img="$img_name$img_ext"
xz -z -8 "${OIB_DIR}/deploy/$dep_name/$my_img"

# after
cp "${OIB_DIR}/build.log" "$play_home/build_$mybuild_$datestamp.log"
cp "${OIB_DIR}/sdcard.log" "$play_home/sdcard_$mybuild_$datestamp.log"