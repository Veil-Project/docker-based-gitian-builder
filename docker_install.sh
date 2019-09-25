#!/bin/bash

# doc: bash docker_install.sh 
# example: bash docker_install.sh 
# parameters: ---   
# This script will install docker.

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

echo -n "Docker is required. Would you like to install it now (Y/N)?"
read b_install_docker
if [ ! -z ${b_install_docker} ] && [[ ! "$b_install_docker" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo -e "${magenta}Exiting -- Docker is required!${reset}"
    exit 1
fi
    
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io
echo -e "${green}Docker install complete.${reset}"





