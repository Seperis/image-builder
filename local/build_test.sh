#!/bin/bash

# build
my_build="arm64_xfce_bkwm_12.4_v6.1ti_play"

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=$PROJ/beagle_play
bb_home=$PROJ/bb_black 

# variables
time=$(date +%Y-%m-%d)
timestamp=$(date +%Y%m%d%T)
kernel_version="v6.1ti"

get_build_var() {
	ps=$1
	val=$( cat $my_build.conf | grep -w "$ps" | cut -d "=" -f2 | sed -e 's/\"//g' )
	echo "$val"
}

get_image_name() {
	ps_buildver=$1
	# image name - format: [ [board abbr]-[os codename]-[release]-[image type]e-[kernel version]-[time]-[build_version] ]
	board_abb=$( cut -d "_" -f6 <<< $my_build )
	os_code=$( get_build_var "deb_codename" )
	os_rel=$( get_build_var "release" )
	img_type=$( get_build_var "image_type" )
	img_name="$board_abb-$os_code-$os_rel-$img_type-$kernel_version-$time-$ps_buildver"
	# return
	echo $img_name

}
# copy files
sh_file=$( get_build_var "chroot_script" )
echo $sh_file
#cp local/$my_build.conf configs/custom-debian.conf 
#cp local/$sh_file target/chroot/custom-debian.sh

# run builder
echo
echo "Starting RootStock-NG.sh"
#sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log
echo
echo "RootStock-NG done"

# get build name from latest version
build_name=$( cat "latest_version" )
echo $build_name

if [ -e deploy/$build_name ]; then
	# continue
	build_ver="bv1-dev"
	# image name - format: [ board_abb-os_codename-os_rel-os_type-kern_ver-time-build_ver ]
	image_name$( get_image_name $kern_ver $time $build_ver )
	echo "$image_name"
fi


