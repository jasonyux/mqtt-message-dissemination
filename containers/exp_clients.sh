#!/bin/bash

SUB_IP=$1
PUB_IP=$2
SUB_PORT=8088
PUB_PORT=8088

DIRECTORY=$3
PUB_WAIT=$4
TOPICS=a7

if [ -z "$SUB_IP" ] || [ -z "$PUB_IP" ] || [ -z "$DIRECTORY" ]; then
	echo "usage: ./exp_clients.sh <sub_broker_ip> <pub_broker_ip> <path> <pub_wait>"
	exit
fi

if [ -z "$PUB_WAIT" ]; then
	PUB_WAIT=5
fi

SUB_COMMAND="${DIRECTORY}/subscriber_args ${SUB_IP} ${SUB_PORT} 1"
# this is used for heat map
#PUB_COMMAND="${DIRECTORY}/publisher_args ${PUB_IP} ${PUB_PORT} 2 1000 5 a0 a0 a0 a0 a0"

# this is used for delay map
PUB_COMMAND="${DIRECTORY}/publisher_args_dup ${PUB_IP} ${PUB_PORT} 100 1000 100 a0"

#DOC_SUB_COMMAND="docker exec -d clients_sub_1 sh -c '${SUB_COMMAND}'"

# sh -c "$DOC_SUB_COMMAND"
#eval "$DOC_SUB_COMMAND"
#echo "[ LOG ] executed '${DOC_SUB_COMMAND}'"
eval "docker exec -d clients_sub_1 sh -c '${SUB_COMMAND}'"
echo "[LOG] executed docker exec -d clients_sub_1 sh -c '${SUB_COMMAND}'"

echo "[ LOG ] sleeping for ${PUB_WAIT}"
sleep ${PUB_WAIT}

eval "docker exec -d clients_pub_1 sh -c '${PUB_COMMAND}'"
echo "[ LOG ] executed docker exec -d clients_pub_1 sh -c '${PUB_COMMAND}'"
