#!/bin/bash
echo $1
DIRECTORY=$1
TIMEOUT=$2
COUNT=1
TOP_COMMAND="timeout ${TIMEOUT} top -b -d 1 > "
TCP_COMMAND="timeout ${TIMEOUT} tcpdump -i eth0 -w "

if [ -z "$DIRECTORY" ] || [ -z "$TIMEOUT" ]; then
	echo "usage: ./exp_data.sh <path> <timeout>"
	exit
fi

# eval "${TOP_COMMAND}test.txt"

while [ $COUNT -le 7 ]; do
#	eval "docker exec -d sub_flood_broker_${COUNT} touch ${DIRECTORY}/b${COUNT}/cpu.txt"
	eval "docker exec -d sub_flood_broker_${COUNT} sh -c '${TOP_COMMAND}${DIRECTORY}/b${COUNT}/cpu.txt'"
	echo "[LOG] executed docker exec -d sub_flood_broker_${COUNT} sh -c '${TOP_COMMAND}${DIRECTORY}/b${COUNT}/cpu.txt'"

	eval "docker exec -d sub_flood_broker_${COUNT} ${TCP_COMMAND}${DIRECTORY}/b${COUNT}/b${COUNT}.pcap"
	echo "[LOG] executed docker exec -d sub_flood_broker_${COUNT} ${TCP_COMMAND}${DIRECTORY}/b${COUNT}/b${COUNT}.pcap"

	COUNT=$(($COUNT + 1))
done
