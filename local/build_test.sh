#!/bin/bash

# build
#my_build="arm64_xfce_bkwm_12.4_v6.1ti_play"
flag="yes"

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=$PROJ/beagle_play
bb_home=$PROJ/bb_black 

# build array
arr=( "arm64_min_bkwm_12.4_v6.1ti_play" "arm64_xfce_bkwm_12.4_v6.1ti_play" \
			"armhf_iot_bkwm_12.4_v6.1ti_bone" "armhf_min_bkwm_12.4_v6.1ti_bone" )

echo
echo "Select build:"
echo "1. arm64_min_bkwm_12.4_v6.1ti_play"
echo "2. arm64_xfce_bkwm_12.4_v6.1ti_play"
echo "3. armhf_iot_bkwm_12.4_v6.1ti_bone"
echo "4. armhf_min_bkwm_12.4_v6.1ti_bone"
read -r -p "Your selection: " var_build
num=$(( var_build - 1 ))
my_build="${arr[$num]}"

# variables
time=$(date +%Y-%m-%d)
date=$(date +%Y%m%d%T)
kernel_version="v6.1ti"
board_abbr=$( cut -d "_" -f6 <<< $my_build )

get_build_var() {
	ps=$1
	# options [ release image_type deb_distribution deb_codename deb_arch
	if [ "$ps" = "deb_codename" ]; then
		val=$( cat local/$my_build.conf | grep -w "$ps" | sed -n 2p | cut -d "=" -f2 | sed -e 's/\"//g' )
	else
		val=$( cat local/$my_build.conf | grep -w "$ps" | cut -d "=" -f2 | sed -e 's/\"//g' )
	fi
	echo "$val"
}

get_image_size() {
	img_type=$( get_build_var "image_type" )
	if [ "$img_type" = "minimal" ]; then
		if [ "$board_abbr" = "bone" ]; then
			bld_size="2gb"
		else
			bld_size="6gb"
		fi
	elif [ "$img_type" = "iot" ]; then
		bld_size="4gb"
	else
		bld_siz="10gb"
	fi
	# return
	echo "$bld_size"
}

get_image_name() {
	ps_bld=$1
	# image name - format: [ [board abbr]-[os codename]-[release]-[image type]e-[kernel version]-[time]-[build_version] ]
	os_code=$( get_build_var "deb_codename" )
	os_rel=$( get_build_var "release" )
	img_type=$( get_build_var "image_type" )
	img_name="$board_abbr-$os_code-$os_rel-$img_type-$kernel_version-$time-$ps_bld"
	# return
	echo $img_name
}

my_conf="$my_build.conf"
if [ ! -f local/"$my_conf" ]; then
	echo "Configuration file does not exist. Start over."
	flag="no"
else
	echo "Configuration file exists"
fi

if [ $flag = "yes" ]; then
	# copy files
	my_sh=$( get_build_var "chroot_script" )
	echo "Configuration file: $my_conf"
	echo "Script file: $my_sh"
	cp local/$my_conf configs/custom-debian.conf
	cp local/$my_sh target/chroot/custom-debian.sh
	chmod 777 target/chroot/custom-debian.sh
	if [ ! -f configs/custom-debian.conf ]; then
		echo "Configuration file was not copied successfully. Start over."
		flag="no"
	else
		echo "Configuration file copied successfully"
		if [ ! -f target/chroot/custom-debian.sh ]; then
			echo "Script file was not copied successfully.  Start over."
			flag="no"
		else
			echo "Script file copied successfully"
		fi
	fi
fi

if [ "$flag" = "yes" ]; then
	echo "Starting RootStock-Ng.sh"
	echo "sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log"
	sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log
	echo
	echo "RootStock-NG.sh done"
	build_name=$( cat "latest_version" )
	echo "$build_name"
	if [ ! -e deploy/$build_name ]; then
		echo "Deploy folder was not successful. Start over."
		flag="no"
	else
		echo "Deploy folder found. Continuing."
		flag="yes"
	fi
fi

if [ $flag = "yes" ]; then
	# continue
	sdlog="${OIB_DIR}/sdcard.log"
	build_ver="bv1-dev"
	timestamp="_$date"

	# get image size for tag
	img_size=$( get_image_size )
  echo
	echo "Image Size: $img_size"

	# get tags
	if [ "$board_abbr" = "play" ]; then
		opt_tags="--dtb beagleplay --boot_label BEAGLEPLAY --rootfs_label PLAY"
		board_home="$play_home"
	else
		opt_tags="--dtb beaglebone --boot_label BEAGLEBONE --rootfs_label BONE"
		board_home="$bb_home"
	fi
	echo
	echo "Tags: $opt_tags"
	echo "Board Home: $board_home"

	# get image name
	echo "Getting image name"
	image_name=$( get_image_name $build_ver )
	echo "$image_name"

	cd deploy/$build_name
	echo "Does this look correct?"
	echo "sudo ./setup_sdcard.sh --img-${img_size} $image_name $opt_tags 2>&1 | tee $sdlog"
	read -r -p "Your answer: " var_answer
	if [ "$var_answer" != "no" ]; then
		echo
		echo "Starting setup_sdcard.sh"
		sudo ./setup_sdcard.sh --img-${img_size} $image_name $opt_tags 2>&1 | tee $sdlog
		echo
		echo "Setup complete"
		# get image size
		my_img="$image_name-${img_size}.img"
		my_img_size_bytes=$( stat -c %s "$my_img" )
		echo
		echo "Image: $my_img"
		echo "Size: $my_img_size ( $my_img_size_bytes B )"
		echo
		echo "Starting compression"
		sudo xz -z -8 -v "$my_img"
		echo
		echo "Compression complete"
		echo
		comp_img="$my_img".xz
		comp_img_size_bytes=$( stat -c %s "$comp_img" )
		comp_img_size=$( ls -lh "$comp_img" )
		echo
		echo "Compressed Image: $comp_img"
		echo "Size: $comp_img_size_bytes B"
		echo
		echo "Moving image"
		echo "${OIB_DIR}/$comp_img $PROJ/images/$comp_img"
		cp "${OIB_DIR}/$comp_img" "$PROJ/images/$comp_img"
		echo "Moving logs"
		echo "${OIB_DIR}/build.log $board_home/build_$my_build$timestamp.log"
		echo "${OIB_DIR}/sdcard.log $board_home/sdcard_$my_build$timestamp.log"
		cp "${OIB_DIR}/build.log" "$board_home/build_$my_build$timestamp.log"
		cp "${OIB_DIR}/sdcard.log" "$board_home/sdcard_$my_build$timestamp.log"
	fi
fi


