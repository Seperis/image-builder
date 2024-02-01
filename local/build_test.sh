#!/bin/bash

# testing data
#my_build="arm64_xfce_bkwm_12.4_v6.1ti_play"

# flags
flag="yes"

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=$PROJ/beagle_play
bb_home=$PROJ/bb_black 
bbai_home=$PROJ/bb_ai64

# variables
time=$(date +%Y-%m-%d)
date=$(date +%Y%m%d%T)

# build array
arr=( "arm64_xfce_bkwm_12.4_v5.10ti_play" "arm64_min_bkwm_12.4_v6.1ti_play" "arm64_xfce_bkwm_12.4_v6.1ti_play" \
		"arm64_xfce_bkwm_12.4_v6.7k3_play" "arm64_min_bkwm_12.4_vML_play" \
		"armhf_iot_beye_11.8_v5.10ti_bone" "armhf_xfce_bkwm_12.4_v5.10ti_bone" "armhf_iot_bkwm_12.4_v5.10ti_bone" \
		"armhf_iot_bkwm_12.4_v6.1ti_bone" "armhf_min_bkwm_12.4_v6.1ti_bone" )

echo "Log: starting log for build_test.sh"
echo "Log: selecting build to create."
echo
echo "Select build:"
echo "1. arm64_xfce_bkwm_12.4_v5.10ti_play"
echo "2. arm64_min_bkwm_12.4_v6.1ti_play"
echo "3. arm64_xfce_bkwm_12.4_v6.1ti_play"
echo "4. arm64_xfce_bkwm_12.4_v6.7k3_play"
echo "5. arm64_min_bkwm_12.4_vML_play"
echo "6. armhf_iot_beye_11.8_v5.10ti_bone"
echo "7. armhf_xfce_bkwm_12.4_v5.10ti_bone"
echo "8. armhf_iot_bkwm_12.4_v5.10ti_bone"
echo "9. armhf_iot_bkwm_12.4_v6.1ti_bone"
echo "10. armhf_min_bkwm_12.4_v6.1ti_bone"
read -r -p "Your selection: " var_build
# validate
if [ $var_build -eq 0 ] || [ $var_build -gt 10 ]; then
	echo "Debug: that is not a valid build number"
	flag="no"
else
	num=$(( var_build - 1 ))
	my_build="${arr[$num]}"
	if [ -z "$my_build" ]; then
		echo "Debug: $my_build not valid or variable is blank"
		echo "Debug: $var_build"
		flag="no"
	else
		echo "Log: $my_build is a valid build selection"
		# set kernel and board variables
		kernel_version=$( cut -d "_" -f5 <<< "$my_build" )
		board_abbr=$( cut -d "_" -f6 <<< "$my_build" )
	fi
fi

# functions
get_build_var() {
	ps=$1
	# options [ release image_type deb_distribution deb_codename deb_arch ]
	my_conf="local/$my_build.conf"
	val=$( cat "$my_conf" | grep -w "$ps" | cut -d "=" -f2 | sed -e 's/\"//g' )
	# deb_codename, deb_arch
	if [ "$ps" = "deb_codename" ] || [ "$ps" = "deb_arch" ]; then
		val=$( sed -n 2p <<< "$val" )
	fi
	# return
	echo "$val"
}

get_size_tag() {
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
	# format:[board abbr]-[os codename]-[release]-[image type]-[kernel version]-[time]-[build version]
	os_code=$( get_build_var "deb_codename" )
	os_rel=$( get_build_var "release" )
	img_type=$( get_build_var "image_type" )
	img_name="$board_abbr-$os_code-$os_rel-$img_type-$kernel_version-$time-$ps_bld"
	# return
	echo "$img_name"
}

# main
if [ "$flag" = "yes" ]; then
	# configuration file
	my_conf="$my_build.conf"
	conf_origin="local/$my_conf"
	if [ ! -f "$conf_origin" ]; then
		echo "Debug: $conf_origin does not exist"
		echo "Debug: $my_build"
		echo "Debug: $my_conf"
		flag="no"
	else
		echo "Log: $conf_origin found"
	fi
fi

# script file
if [ "$flag" = "yes" ]; then
	# script file
	my_sh=$( get_build_var "chroot_script" )
	sh_origin="local/$my_sh"
	# check if file exists
	if [ ! -f "$sh_origin" ]; then
		echo "Debug: $sh_origin does not exist."
		echo "Debug: $my_sh"
		flag="no"
	else
		echo "Log: $sh_origin found"
	fi
fi

# copy conf file
if [ "$flag" = "yes" ]; then
	conf_dest="configs/custom-debian.conf"
	echo "Log: copying and renaming configuration file"
	echo "Log: [cp $conf_origin $conf_dest]"
	cp "$conf_origin" "$conf_dest"
	if [ ! -f "$conf_dest" ]; then
		echo "Debug: $my_conf was not copied successfully"
		echo "Debug: $conf_origin"
		echo "Debug: $conf_dest"
		flag="no"
	else
		echo "Log: $my_conf copied successfully to $conf_dest"
	fi
fi

# copy script file
if [ "$flag" = "yes" ]; then
	sh_dest="target/chroot/custom-debian.sh"
	echo "Log: copying and renaming script file"
	echo "Log: [cp $sh_origin $sh_dest]"
	cp "$sh_origin" "$sh_dest"
	chmod 777 "$sh_dest"
	if [ ! -f "$sh_dest" ]; then
		echo "Debug: $my_sh was not copied successfully."
		echo "Debug: $sh_origin"
		echo "Debug: $sh_dest"
		flag="no"
	else
		echo "Log: $my_sh copied successfully to $sh_dest"
	fi
fi

# start RootStock
if [ "$flag" = "yes" ]; then
	echo "Log: Starting RootStock-Ng.sh"
	echo "Log: [sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log]"
	sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log
	echo
	echo "Log: RootStock-NG.sh done"
	build_name=$( cat "latest_version" )
	if [ ! -e deploy/$build_name ]; then
		echo "Debug: deploy/$build_name does not exist."
		echo "Debug: $build_name"
		flag="no"
	else
		echo "Log: deploy/$build_name created successfully"
	fi
fi

if [ "$flag" = "yes" ]; then
	# continue
	sdlog="${OIB_DIR}/sdcard.log"
	build_ver="bv1dev"
	timestamp="_$date"

	# get image size for tag
	echo "Log: getting size tag for setup_sdcard.sh"
	size_tag=$( get_size_tag )
	if [ -z "$size_tag" ]; then
		echo "Debug: tag was empty. Using default value 8gb"
		size_tag="8gb"
	fi
	echo "Log: size tag is $size_tag"

	# get option tags
	echo "Log: getting option tags for setup_sdcard.sh  and home folder of board"
	if [ "$board_abbr" = "play" ]; then
		opt_tags="--dtb beagleplay --boot_label BEAGLEPLAY --rootfs_label PLAY --distro-bootloader --hostname medusa"
		board_home="$play_home"
		board_model="Beagleplay"
	elif [ "$board_abbr" = "bbai" ]; then
 		opt_tags="--dtb"
   		board_home="$bbai_home"
	 	board_model="BeagleBone AI-64"
   	else
		opt_tags="--dtb beaglebone --boot_label BEAGLEBONE --rootfs_label BONE --hostname circe"
		board_home="$bb_home"
		board_model="BeagleBone Black"
	fi
	echo "Log: option tags are $opt_tags"
	echo "Log: board home folder is $board_home"

	# get image name
	echo "Log: Getting image name"
	image_name=$( get_image_name $build_ver )
	if [ -z "$image_name" ]; then
		echo "Debug: image name was empty. Using default $build_name"
		image_name="$build_name"
	fi
	echo "Log: image name is $image_name"

	cd deploy/$build_name
	work_dir="${OIB_DIR}/deploy/$build_name"
	echo "Log: Staring setup_sdcard.sh"
	echo "Log: [sudo ./setup_sdcard.sh --img-${size_tag} $image_name $opt_tags 2>&1 | tee $sdlog]"
	sudo ./setup_sdcard.sh --img-${size_tag} $image_name $opt_tags 2>&1 | tee $sdlog
	echo "Log: setup_sdcard.sh complete"
	# get image file 
	my_image="$image_name-${size_tag}.img"
	# validating image creation
	if [ ! -f "$work_dir/$my_image" ]; then
		echo "Debug: $my_image does not exist or that is not the correct name."
		echo "Debug: $work_dir/$my_image"
		echo "Debug: $my_image"
		flag="no"
	else
		echo "Log: $my_image created successfully."
		my_image_size=$( stat -c %s "$my_image" )
		echo "Log: $my_image $my_image_size B"
	fi
fi

# compress image
if [ "$flag" = "yes" ]; then
	echo "Log: Starting compression"
	echo "Log: [sudo xz -z -8 -v $my_image]"
	sudo xz -z -8 -v "$my_image"
	echo "Log: compression complete"
	comp_image="$my_image".xz
	# validating compression
	if [ ! -f "$work_dir/$comp_image" ]; then
		echo "Debug: $comp_image does not exist or the name is wrong"
		echo "Debug: $work_dir/$comp_image"
		echo "Debug: $comp_image"
		flag="no"
	else
		echo "Log: $comp_image created successfully."
		comp_image_size=$( stat -c %s "$comp_image" )
		echo "Log: $comp_image $comp_image_size B"
		echo
  		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo "~~ Build: deploy/$build_name"
		echo "~~ Image File: $my_image"
		echo "~~ Compressed: $comp_image"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	fi
fi

# clean up
if [ "$flag" = "yes" ]; then
	echo "Log: copying image to image folder"
	echo "Log: [cp $work_dir/$comp_image $PROJ/images/$comp_image]"
	cp "$work_dir/$comp_image" "$PROJ/images/$comp_image"
	# validate copy
	if [ ! -f "$PROJ/images/$comp_image" ]; then
		echo "Debug: $comp_image was not copied successfully"
		echo "Debug: $PROJ/images/$comp_image"
		flag="no"
	else
		echo "Log: $comp_image was copied successfully to $PROJ/images."
	fi
fi

# moving log files
if [ "$flag" = "yes" ]; then
	lext="$my_build$timestamp.log"
	echo "Log: copying log files to board folder"
	echo "Log: [cp ${OIB_DIR}/build.log $board_home/build_$lext]"
	cp "${OIB_DIR}/build.log" "$board_home/build_$lext"
	# validate copy
	if [ ! -f "$board_home/build_$lext" ]; then
		echo "Debug: build.log was not copied successfully."
	else
		echo "Log: build.log was copied successfully to $board_home."
	fi
	echo "Log: [cp ${OIB_DIR}/sdcard.log $board_home/sdcard_$lext]"
	cp "${OIB_DIR}/sdcard.log" "$board_home/sdcard_$lext"
	if [ ! -f "$board_home/sdcard_$lext" ]; then
		echo "Debug: sdcard.log was not copied successfully."
	else
		echo "Log: sdcard.log was copied successfully to $board_home."
	fi
fi

if [ "$flag" = "no" ]; then
	echo "There were problems during script execution. Check to see what they were."
fi
echo "Log: Image build complete complete"
# log
log_date=$(date +%m/%d/%Y); # log date
log_time=$(date +%T); # log time
log="$PROJ/beagle_image.log"
log_format="%-12s %-10s %-18s %-70s %-13s %-40s\n"
printf "$log_format" "$log_date" "$log_time" "$board_model" "$my_image" "Scomp_image" "$my_build" >>$log
