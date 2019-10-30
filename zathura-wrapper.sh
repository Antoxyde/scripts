#!/bin/bash

if ! pidof zathura >/dev/null; then
	zathura $@
fi
