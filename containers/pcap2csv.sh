#!/bin/bash

COUNT=1
PATH=$1
PARAMS="-T fields -e frame.time_relative -e frame.len -e ip.src -e ip.dst \
	-e mqtt.msgtype -e mqtt.qos -e mqtt.topic -e mqtt.msg -e mqtt.msgid \
	-E header=y -E separator=, -E aggregator=^ \
	-d tcp.port==8088,mqtt"

if [ -z "$PATH" ]; then
	echo "usage: ./pcap2csv.sh <path>"
	exit
fi

if [ -d "${PATH}/csv" ]; then
	echo "[ ERROR ] ${PATH}/csv already exists"
	exit
fi

eval "/usr/bin/mkdir ${PATH}/csv"

while [ $COUNT -le 7 ]; do
	eval "/usr/bin/tshark -r ${PATH}/b${COUNT}/b${COUNT}.pcap $PARAMS > ${PATH}/csv/b${COUNT}.csv"
	COUNT=$(($COUNT + 1))
done
