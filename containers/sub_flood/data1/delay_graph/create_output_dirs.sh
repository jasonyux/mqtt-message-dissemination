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

COUNT=0
while [ $COUNT -le 76 ]; do
	CURR_DIR="$BASE_DIR/tc-${COUNT}/linear_sf"
	create_exp_folder "$CURR_DIR"
	CURR_DIR="$BASE_DIR/tc-${COUNT}/linear_pf"
	create_exp_folder "$CURR_DIR"
	COUNT=$(($COUNT + 25))
done

