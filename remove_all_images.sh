#!/bin/bash

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

echo -n "Do you want to remove all docker images(Y/N)? (default: Y): "
read b_delete_images
if [ -z "${b_delete_images}" ] || ([ ! -z "${b_delete_images}" ] && [[ "$b_delete_images" =~ ^([yY][eE][sS]|[yY])+$ ]]); then
    sudo docker images -q | awk '{system("sudo docker rmi " $1)}'
    echo "All docker containers removed."
fi
