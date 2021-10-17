#!/bin/bash

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

sudo docker images -q | awk '{system("sudo docker rmi " $1)}'
echo "All docker images removed."

