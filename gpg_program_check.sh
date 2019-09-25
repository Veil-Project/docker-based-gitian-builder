#!/bin/bash

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

check_for_gpg () {
  hash gpg 2>/dev/null || { echo >&2 "This script requires the 'gpg' program, it may not be installed or not on your path."; exit 1; }
}

if [ -z `check_for_gpg` ]; then
    exit 0
fi

echo -n "gpg is required. Would you like to install it now (Y/N)?"
read b_install_gpg

if [ ! -z "${b_install_gpg}" ];  then
    if [[ "$b_install_gpg" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        echo "Starting gnupg install..."
        sudo apt-get update
        sudo apt-get install gnupg
        echo "gnupg install complete."
        exit 0
    else
        echo "Exiting -- gpg is required!"
        exit 1
    fi
else
    echo "Exiting -- gpg is required!"
    exit 1
fi




