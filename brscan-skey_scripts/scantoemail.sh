#! /bin/sh
set +o noclobber
#
#   $1 = scanner device
#   $2 = friendly name
#   $3 = email address

#
#       100,200,300,400,600
#

resolution=300
format=jpeg
output_file=/tmp/brscan/brscan_"`date +%Y-%m-%d-%H-%M-%S`""_email"

device=$1
mkdir -p /tmp/brscan
sleep  0.1
echo "Retrieving image from $2 to $output_file."
declare -a output_jpg=($(scanimage --batch="${output_file}_%d.jpg" --batch-print --device-name "$device" --resolution $resolution --format $format))
echo "debug: Batch mode images ${output_jpg[@]}." >&2
echo ${output_jpg[@]} | s-nail -s "Scan `date +%Y-%m-%d-%H-%M-%S`" $(printf ' -a %s' ${output_jpg[@]}) -r "$EMAIL_FROM" "$EMAIL_TO" && echo "." && \
rm -f ${output_jpg[@]}
