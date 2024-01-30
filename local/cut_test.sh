#!/bin/bash

my_build="armhf_iot_bkwm_12.4_v5.10ti_bone"
kernel_version=$( cut -d "_" -f5 <<< $my_build )
echo "$kernel_version"
board_abbr=$( cut -d "_" -f6 <<< $my_build )
echo "$board_abbr"
