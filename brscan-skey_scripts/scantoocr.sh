#! /bin/sh
set +o noclobber
#
# $1 = scanner device
# $2 = friendly name
#

#
#       100,200,300,400,600
#
resolution=300
format=pnm
output_file=/tmp/brscan/brscan_"`date +%Y-%m-%d-%H-%M-%S`""_ocr.pdf"

device=$1
mkdir -p /tmp/brscan
sleep  0.1
output_tmp=`mktemp /tmp/brscan/brscan_XXXXXX`
echo "Retrieving image from $2 to $output_file."
declare -a outpnm_tmp=($(scanimage --batch="${output_tmp}_%d.pnm" --batch-print --device-name "$device" --resolution $resolution --format $format))
echo "debug: Batch mode images ${outpnm_tmp[@]}." >&2
convert ${outpnm_tmp[@]} ${output_tmp}.pdf && rm -f $output_tmp ${outpnm_tmp[@]} && \
mv ${output_tmp}.pdf $output_file && echo . && \
/app/bash-onedrive-upload/onedrive-upload $output_file && rm -f $output_file
