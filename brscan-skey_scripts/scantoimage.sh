#! /bin/sh
set +o noclobber
#
# $1 = scanner device
# $2 = friendly name
#

#
#       100,200,300,400,600
#
resolution=600
format=jpeg
output_file=/tmp/brscan/brscan_"`date +%Y-%m-%d-%H-%M-%S`""_image.jpg"

device=$1
mkdir -p /tmp/brscan
sleep  0.1
output_tmp=`mktemp /tmp/brscan/brscan.XXXXXX`
echo "Retrieving image from $2 to $output_file."
scanimage --device-name "$device" --resolution $resolution --format $format > $output_tmp
mv $output_tmp $output_file && echo .
/app/bash-onedrive-upload/onedrive-upload $output_file && rm -f $output_file
