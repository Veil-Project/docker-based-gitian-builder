#!/bin/bash

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

sudo docker ps -a | awk 'FNR > 1 {system("sudo docker rm " $1)}' #FNR > 1 to skip the header row.
echo "All docker containers removed."
