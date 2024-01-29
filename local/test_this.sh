#!/bin/bash
quote_para="s/\"//g"
arr=( release image_type deb_distribution deb_codename deb_arch )
ps_scp="local/arm64_min_bkwm_12.4_v6.1ti_play.conf"
x_name=$( cat "$ps_scp" | grep -w "deb_codename" | cut -d "=" -f1 )
echo $x_name
y_name=$( cat "$ps_scp" | grep -w "deb_codename" | sed -n 2p | cut -d "=" -f2 )
echo $y_name
z_name=$( cat "$ps_scp" | grep -w "deb_codename" | sed -n 2p | cut -d "=" -f2 | sed -e 's/\"//g' )
echo $z_name
#o_name=$( cat "$ps_scp" | grep -w "image_type" | cut -d "=" -f2 )
#p_name=$( sed -e 's/\"//g' <<< "$o_name" )
#q_name=$( cat "$ps_scp" | grep -w "image_type" | cut -d "=" -f2 | sed -e 's/\"//g' )
#echo $o_name
#echo $p_name
#echo $q_name
