#!/bin/bash

# build
#my_build="arm64_xfce_bkwm_12.4_v6.1ti_play"

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=$PROJ/beagle_play
bb_home=$PROJ/bb_black 

# variables
time=$(date +%Y-%m-%d)
date=$(date +%Y%m%d%T)
kernel_version="v6.1ti"
board_abb=$( cut -d "_" -f6 <<< $my_build )

echo
echo "Select build:"
echo "1. arm64_min_bkwm_12.4_v6.1ti_play"
echo "2. arm64_xfce_bkwm_12.4_v6.1ti_play"
echo "3. armhf_iot_bkwm_12.4_v6.1ti_bone"
echo "4. armhf_min_bkwm_12.4_v6.1ti_bone"
read -r -p "Your selection: " my_build

get_build_var() {
	ps=$1
	val=$( cat $my_build.conf | grep -w "$ps" | cut -d "=" -f2 | sed -e 's/\"//g' )
	echo "$val"
}

get_image_name() {
	ps_bld=$1
	# image name - format: [ [board abbr]-[os codename]-[release]-[image type]e-[kernel version]-[time]-[build_version] ]
	os_code=$( get_build_var "deb_codename" )
	os_rel=$( get_build_var "release" )
	img_type=$( get_build_var "image_type" )
	img_name="$ps_abbr-$os_code-$os_rel-$img_type-$kernel_version-$time-$ps_bld"
	# return
	echo $img_name
}

user_dialogue_size() {
	echo "Select image size."
  echo "1. 1gb"
  echo "2. 2gb"
  echo "3. 4gb"
  echo "4. 6gb"
  echo "5. 8gb"
  echo "6. 10gb"
  echo "7. 11gb"
  echo "8. 12gb"
  read -r -p "Your selection: " var_answer
  img_size=$( get_image_size $var_answer )
	# return
	echo $img_size
}

get_image_size() {
	ps_sz=$1
	case $ps_sz in
		1)
			sz=1
			;;
		2)
			sz=2
			;;
	  3)
			sz=4
			;;
	  4)
			sz=6
			;;
	  5)
			sz=8
			;;
	  6)
			sz=10
			;;
	  7)
			sz=11
			;;
		8)
			sz=12
			;;
	  *)
			sz=$ps_sz
			;;
	esac
	# return
	echo $sz
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
	sdlog="${OIB_DIR}/sdcard.log"
	build_ver="bv1-dev"
	timestamp="_$date"
	# get image name
	image_name$( get_image_name $build_ver )
	echo "$image_name"
	# get image size
	img_size=$( user_dialogue_size )

	if [ "$board_abbr" = "play" ]; then
		opt_tags="--dtb beagleplay --boot_label BEAGLEPLAY --rootfs_label PLAY"
		board_home="$play_home"
	else
		opt_tags="--dtb beaglebone --boot_label BEAGLEBONE --rootfs_label BONE"
		board_home-"$bb_home"
	fi

	cd deploy/$build_name
	echo "Starting setup_sdcard.sh"
	sudo ./setup_sdcard.sh --img-$img_size $img_name $opt_tags 2>&1 | tee $sdlog
	echo
	echo "Setup complete"
	# get image size
	my_img="$img_name".img
	my_img_size_bytes=$( stat -c %s "$my_img" )
	my_img_size=$( ls -lh "$my_img" )
	echo
	echo "Image: $my_img"
	echo "Size: $my_img_size ( $my_img_size_bytes B )"
	echo
	echo "Starting compression"
	#sudo xz -z -8 -v "$my_img"
	echo
	echo "Compression complete"
	echo
	comp_img="$my_img".xz
	comp_img_size_bytes=$( stat -c %s "$comp_img" )
	comp_img_size=$( ls -lh "$comp_img" )
	echo
	echo "Compressed Image: $comp_img"
	echo "Size: $comp_img_size ( $comp_img_size_bytes B)"'

	echo
	echo "Moving logs"
	u="_"
	echo "${OIB_DIR}/build.log $board_home/build_$my_build$timestamp.log"
	echo "${OIB_DIR}/sdcard.log $board_home/sdcard_$my_build$timestamp.log"
	#cp "${OIB_DIR}/build.log" "$board_home/build_$my_build$timestamp.log"
	#cp "${OIB_DIR}/sdcard.log" "$board_home/sdcard_$my_build$timestamp.log"
fi


