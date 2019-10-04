#!/bin/bash

# doc: bash push_sigs.sh {signer} {tag or branch} {path to gitian sigs}
# example: bash push_sigs.sh "4x13" "v1.0.4.6" "../gitian.sigs"
# parameters: 
#   {signer} (optional): defaults to "4x13"
#   {tag or branch} (optional): defaults to master
#   {path to gitian sigs} (optional): defaults to ../gitian.sigs
# This script will commit manifest and signature files to the repo referenced at the gitian sigs path.
# You will be prompted for any parameters you don't submit via the cmd line.

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

# Script variables 
version="master"
signer="4x13"

echo -e "${cyan} "
echo "******************************************************************"
echo "****                  Push Manifest to Github                 ****"
echo -e "******************************************************************${reset}"

############################ Functions ##################################
get_input_from_user () {
    get_signer_name
    get_version
    get_path_to_gitian_sigs
}

process_args () {
  if [ ! -z "${1}" ]; then
    signer=${1}
  fi
  if [ ! -z "${2}" ]; then
    version=${2}
    if [[ "$version" =~ ^([vV]) ]]; then 
      version="${version:1}" # remove the v from the front of the tag.
    fi
  fi
  if [ ! -z "${3}" ]; then
    path_to_gitian_sigs=${3}
  fi
}

get_signer_name () {
  default=$(whoami)
  if [ -z "${signer}" ]; then
    echo -n "Enter desired signing name (default: $default):"
    read signer
    if [ -z "${signer}" ]; then
      signer=$default
    fi
  fi
}

get_version() {
  if [ -z "${version}" ]; then
    echo -n "Enter desired version number (default: master):"
    read version
    if [ -z "${version}" ]; then
      version="master"
    fi
  fi
}

get_path_to_gitian_sigs () {
for _ in once; do
    if [ -z "${path_to_gitian_sigs}" ]; then
        # Set the default path
        path_to_gitian_sigs=../gitian.sigs

        # Check for the default path
        echo "Checking for gitian.sigs directory: ${path_to_gitian_sigs}."
        if [ -d "${path_to_gitian_sigs}" ]; then
            echo -e "${green}Gitian.sigs directory found.${reset}"
            echo -n "Would you like to use this directory(Y/N)? (default: Y):"
            read b_use_default_sigs
            if [ -z "${b_use_default_sigs}" ] || ([ ! -z "${b_use_default_sigs}" ] && [[ "$b_use_default_sigs" =~ ^([yY][eE][sS]|[yY])+$ ]]); then
                break
            fi
        fi     

        while [ 1 ]; do
            echo -n "Please enter the path to gitian.sigs directory: "
            read path_to_gitian_sigs
            if [ -z "${path_to_gitian_sigs}" ]; then
            path_to_gitian_sigs=../gitian.sigs
            fi
            if [ ! -d "${path_to_gitian_sigs}" ]; then
            echo "path: ${path_to_gitian_sigs} does not exist."
            else
            break
            fi
        done
        
        echo -e "${magenta}WARNING: Moving, signing and pushing sigs will be skipped.${reset}"                        
    fi
done
echo -e "${green}Gitian.sigs directory set to: ${path_to_gitian_sigs}${reset}"
}

check_for_gpg () {
  hash gpg 2>/dev/null || { echo >&2 "This script requires the 'gpg' program, it may not be installed or not on your path."; exit 1; }
}
############################ Functions ##################################

process_args $1 $2 $3

check_for_gpg

get_input_from_user

cd ${path_to_gitian_sigs}

git add $version-linux/$signer
git add $version-win/$signer
git add $version-osx/$signer
git commit -a -m "Add $version unsigned sigs for $signer"
git pull --rebase origin master
git push


