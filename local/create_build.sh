#!/bin/bash
# options
# architecture options: armhf arm64
# os version: console iot minimal xfce

# passed variable 
x=$1

# build
#mybuild="arm64_xfce_bkwm_12.4_v6.1ti_play"
my_build=$x

# paths
OIB_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
PROJ=/home/jennifer/projects/beaglebone
play_home=$PROJ/beagle_play
bb_home=$PROJ/bb_black 

get_build_var() {
	ps=$1
	val=$( cat "my_build" | grep -w "$ps" | cut -d "=" -f2 | sed -e 's/\"//g' )
	echo "$val"
}
# os name - options: debian ubuntu
#os_name="debian"
os_name=$(get_build_var "deb_distribution")

get_osversion(){
	ps_bd=$1
	os_verac=$( cut -d "_" -f2 <<< $ps_bd )
	if [ "$os_verac" = "min" ]; then
		os_version="minimal"
	elif [ "$os_verac" = "con" ]; then
		os_version="console"
	else
		os_version="$os_verac"
	fi
	# return
	echo "$os_version"
}

get_oscodename() {
	#ps_co=$1
	os_codeac=$( cut -d "_" -f3 <<< $my_build )
	if [ "$os_codeac" = "bkwm" ]; then
		os_codename="bookworm"
	fi
	# return
	echo "$os_codename"
}

get_size_tag() {
	ps_ver=$1
	ps_arch=$2
	# size_tag_options:--img-1gb --img-2gb --img-4gb --img-6gb --img-8gb --img-10gb
	if [ $ps_ver = "iot" ]; then
		size_tag="--img-4gb"
	elif [ $ps_ver = "minimal" ]; then
		if [ $ps_arch = "armf" ]; then
			size_tag="--img-2gb"
		else
			size_tag="--img-6gb"
		fi
	elif [ $ps_ver = "xfce" ]; then
		size_tag="--img-10gb"
	fi
	# return
	echo "$size_tag"
}

get_option_tags() {
	ps_arch=$1
	if [ "$ps_arch" = "arm64" ] ; then
		tags="--dtb beagleplay --boot_label BEAGLEPLAY --rootfs_label PLAY --hostname circe"
	else
		tags="--dtb beaglebone --boot_label BEAGLEBONE --rootfs_label BONE --hostname medusa --enable-cape-universal"
	fi
	# return
	echo "$tags"
}

get_log_dest() {
	ps_bd=$1
	if [ "$ps_bd" = "play" ]; then
		fldr="$play_home"
	else
		fldr="$bb_home"
	fi
	# return
	echo $fldr
}

# variables
time=$(date +%Y-%m-%d)
timestamp=$(date +%Y%m%d%T)

# copy sh and configs
#board_arch=$( cut -d "_" -f1 <<< $my_build )
board_arch=$( get_build_var "deb_arch" )
if [ "$board_arch" = "armhf" ]; then
	my_sh=armhf_bkwm_custom-debian.sh 
else
	my_sh=arm64_bkwm_custom-debian.sh
fi

# copy files
#cp local/$my_build.conf configs/custom-debian.conf
#cp local/$my_sh target/chroot/custom-debian.sh
#echo "Copy complete"

# run builder
echo
echo "Starting RootStock-NG.sh"
#sudo ./RootStock-NG.sh -c custom-debian 2>&1 | tee build.log
echo
echo "RootStock-NG done"

# deploy folder - format: [operating system]-[release number]-[os version]-[board architecture]-[date]
#os_rel=$( cut -d "_" -f4 <<< $my_build )
os_rel=$( get_build_var "release" )
#os_version=$( get_osversion "$my_build" )
image_type=$( get_build_var "image_type" )
dep_name="$os_name-$os_rel-$image_type-$board_arch-$time"

echo
echo "deploy/$dep_name"

if [ -d deploy/$dep_name ]; then
	# log
	log="${OIB_DIR}/sdcard.log"
	# name variables
	#board_ac=$( cut -d "_" -f6 <<< $my_build )
	os_codename=$( get_oscodename )
	os_codename=$( get_build_var "deb_codename" )
	kern_ver=$( cut -d "_" -f5 <<< $my_build )
	build_ver="bv1-dev"
	# image name - format: [ board_ac-os_codename-os_rel-os_type-kern_ver-date-build_ver ]
	img_name="$board_ac-$os_codename-$os_rel-$os_version-$kern_ver-$time-$build_ver"
	# get tags
	size_tag=$( get_size_tag $os_version $board_arch )
	opt_tags=$( get_option_tags $board_ac )
	
	# sd
z	echo
	echo "SD Card"
	echo "setup_sdcard.sh $size_tag $img_name $opt_tags 2>&1 | tee $log"
	if [ -f "${OIB_DIR}/deploy/$dep_name/setup_sdcard.sh" ]; then
		cd deploy/$dep_name
		echo "Starting setup_sdcard.sh"
		sudo ./setup_sdcard.sh $size_tag $img_name $opt_tags 2>&1 | tee $log
		echo
		echo "setup_sdcard.sh done"
	else
		echo "setup_sdcard.sh does not existoes not exist"
	fi

	# compression
	my_img="$img_name.img"

	echo
	echo "Compression"
	echo "$my_img"
	echo "xz -z -8 $my_img"
	xz -z -8 "${OIB_DIR}/deploy/$dep_name/$my_img"

	# after
	u="_"
	log_dest=$( get_log_dest $board_ac)
	echo
	echo "Log destinations"
	echo "$log_dest/build_$my_build$u$timestamp.log"
	echo "$log_dest/sdcard_$my_build$u$timestamp.log"
	cp "${OIB_DIR}/build.log" "$log_dest/build_$my_build_$timestamp.log"
	cp "${OIB_DIR}/sdcard.log" "$log_dest/sdcard_$my_build_$timestamp.log"
fi