#!/bin/bash

create_exp_folder()
{
	DIR_NAME=$1
	echo "[ DEBUG ] at '$DIR_NAME'"
	if [ ! -d "$DIR_NAME" ]; then
		mkdir "$DIR_NAME"
		pushd "$DIR_NAME"
		mkdir b{1..7}
		popd
	fi
}

BASE_DIR=$1

if [ -z $BASE_DIR ] || [ ! -d "$BASE_DIR" ]; then
	echo "usage ./create_output_dirs <base_dir_path>"
	exit
fi

COUNT=1
while [ $COUNT -le 5 ]; do
	COUNT_2=1
	while [ $COUNT_2 -le 7 ]; do
		CURR_DIR="$BASE_DIR/SPR_${COUNT}-4/OI_${COUNT_2}-7/linear_sf"
		create_exp_folder "$CURR_DIR"
		CURR_DIR="$BASE_DIR/SPR_${COUNT}-4/OI_${COUNT_2}-7/linear_pf"
		create_exp_folder "$CURR_DIR"
		COUNT_2=$(($COUNT_2 + 2))
	done
	COUNT=$(($COUNT + 1))
done

