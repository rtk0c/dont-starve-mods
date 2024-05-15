#!/bin/bash

MOD_DIR="$1/DST_ClientTweaks"
echo "Destroying $MOD_DIR and copying our files to it."
read -p "Do you want to continue? [y/N]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rm -r "$MOD_DIR"
	# Copies contents of src/, but not the directory itself
	# https://unix.stackexchange.com/a/180987
    cp -r ./src/. "$MOD_DIR"
fi
