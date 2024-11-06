#!/bin/bash

# Algorithm from
# https://forums.kleientertainment.com/forums/topic/28369-reading-save-files/

# https://unix.stackexchange.com/a/181938
TMPFILE=$(mktemp /tmp/decode_data.XXXXXX)

DATA_FILE=$1

dd if="$DATA_FILE" bs=1 skip=11 | base64 -d > $TMPFILE
dd if=$TMPFILE bs=1 skip=16 | zlib-flate -uncompress

rm $TMPFILE
