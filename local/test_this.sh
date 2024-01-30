#!/bin/bash
quote_para="s/\"//g"
arr=( release image_type deb_distribution deb_codename deb_arch )
ps_scp="arm64_min_bkwm_12.4_v6.1ti_play.conf"

### WORKING ###
# deb_codename, deb_arch
#z_name=$( cat "$ps_scp" | grep -w "deb_arch" | sed -n 2p | cut -d "=" -f2 | sed -e 's/\"//g' )
#echo $z_name
# release, image_type, deb_distribution
#q_name=$( cat "$ps_scp" | grep -w "image_type" | cut -d "=" -f2 | sed -e 's/\"//g' )
#echo $q_name

### TESTING ###
for i in "${arr[@]}"; do
	qx_name=$( cat "$ps_scp" | grep -w "$i" | cut -d "=" -f2 | sed -e 's/\"//g' )
	if [ "$i" = "deb_codename" ] || [ "$i" = "deb_arch" ]; then
		qx_name=$( sed -n 2p <<< "$qx_name" )
	fi
	echo "i: $qx_name"
done
#r_name=$( cat "$ps_scp" | grep -w "deb_codename" | cut -d "=" -f2 | sed -e 's/\"//g' | sed -n 2p )
#echo $r_name
#nx_name=$( cat "$ps_scp" | grep -w "image_type" )
#ox_name=$( cat "$ps_scp" | grep -w "deb_codename" )
#o_name=$( cat "$ps_scp" | grep -w "image_type" | cut -d "=" -f2 )
#p_name=$( sed -e 's/\"//g' <<< "$o_name" )

