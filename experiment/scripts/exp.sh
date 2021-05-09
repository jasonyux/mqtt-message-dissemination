#!/bin/bash

BROKER_DIRECTORY=$1
TIMEOUT=$2

SUB_IP=$3
PUB_IP=$4
CLI_DIRECTORY=$5
PUB_WAIT=$8
BROKER_PROGRAM=$6
BROKER_CONFIG=$7

if [ -z "$BROKER_DIRECTORY" ] || [ -z "$TIMEOUT" ] || [ -z "$SUB_IP" ] || [ -z "$PUB_IP" ] || [ -z "$CLI_DIRECTORY" ] || [ -z $BROKER_PROGRAM ] || [ -z $BROKER_CONFIG ] ; then
		echo "usage: ./exp.sh <broker_data_path> <broker_timeout> <sub_broker_ip> <pub_broker_ip> <cli_path> <broker_program_name> <broker_config_filename> <pub_wait>"
			exit
fi

echo "[ LOG ] ----- restart_brokers.sh"
./restart_brokers.sh $BROKER_PROGRAM $BROKER_CONFIG

echo "[ LOG ] Necessary Sleeping for 10 sec"
sleep 10 # ensures that broker from previous command wakes up

echo "[ LOG ] ----- exp_data.sh"
sh ./exp_data.sh $BROKER_DIRECTORY $TIMEOUT

sleep 2

echo "[ LOG ] ----- exp_cli.sh"
sh ./exp_clients.sh $SUB_IP $PUB_IP $CLI_DIRECTORY 5
