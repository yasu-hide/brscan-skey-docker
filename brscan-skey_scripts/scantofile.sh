#! /bin/sh
set +o noclobber
#
# $1 = scanner device
# $2 = friendly name
#

#
#       100,200,300,400,600
#
resolution=100
format=pnm
output_file=/tmp/brscan/brscan_"`date +%Y-%m-%d-%H-%M-%S`""_file.pnm"

device=$1
mkdir -p /tmp/brscan
sleep  0.1
mkdir -p /tmp/brscan
output_tmp=`mktemp /tmp/brscan/brscan.XXXXXX`
scanimage --device-name "$device" --resolution $resolution --format $format > $output_tmp  2>/dev/null
mv $output_tmp $output_file