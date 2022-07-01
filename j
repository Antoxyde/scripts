#!/bin/bash

if [ $# != 1 ]; then
   echo "Usage : j <bookmark>"
   exit 1
fi

label="$1"

if [ "$label" = "l" ]; then
    cat ~/.config/bookmarks
    exit 1
fi

entry=$(grep "${label}" ~/.config/bookmarks |awk '{print $2}')


if [ -n "${entry}" ]; then
    echo "Jumping to ${entry}"
    cd "${entry}"
else
    echo "No matching bookmark found."
fi
