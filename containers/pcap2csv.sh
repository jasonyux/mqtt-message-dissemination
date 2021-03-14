#!/bin/bash

COUNT=1
PATH=$1
PARAMS="-T fields -e frame.time_relative -e frame.len -e ip.src -e ip.dst -E header=y -E separator=,"

if [ -z "$PATH" ]; then
	echo "usage: ./pcap2csv.sh <path>"
	exit
fi

eval "/usr/bin/mkdir ${PATH}/csv"

while [ $COUNT -le 7 ]; do
	eval "/usr/bin/tshark -r ${PATH}/b${COUNT}/b${COUNT}.pcap $PARAMS > ${PATH}/csv/b${COUNT}.csv"
	COUNT=$(($COUNT + 1))
done
