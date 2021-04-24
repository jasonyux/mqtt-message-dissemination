#!/bin/bash

DIR="/broker"
PROGRAM=$1

if [ -z "$PROGRAM" ]; then
	echo "[ ERROR ] usage ./restart_brokers.sh <broker_program_name>"
	exit
fi

KILL_COMMAND="kill -9 \$(pidof ${PROGRAM})"
START_COMMAND="sleep 10 && ${DIR}/sub_flood_broker_v3 -c ${DIR}/sub_flood_config.conf -d"

KILL_SUB="kill -9 \$(pidof subscriber_args)"

eval "docker exec -d clients_sub_1 sh -c '${KILL_SUB}'"
echo "[ LOG ] executed docker exec -d clients_sub_1 sh -c '${KILL_SUB}'"

COUNT=1
while [ $COUNT -le 7 ]; do
	eval "docker exec -d sub_flood_broker_${COUNT} sh -c '${KILL_COMMAND}'"
	echo "[ LOG ] ${KILL_COMMAND}"
	sleep 1
	eval "docker exec -d sub_flood_broker_${COUNT} sh -c '${START_COMMAND}'"
	COUNT=$(($COUNT + 1))
done
