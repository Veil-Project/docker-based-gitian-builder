#!/bin/bash

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

# Script variables 
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
base_repo="https://github.com/Veil-Project/"
wallet_repo="${base_repo}veil/"
masterApiEndpoint="https://api.github.com"
username=""
path_to_gitian_sigs=

# OS build flags
b_build_linux="Y"
b_build_osx="Y"
b_build_windows="Y"

############################ Functions ##################################
get_latest_tag () {
  tag_json=$(curl -s "${masterApiEndpoint}/repos/Veil-Project/veil/tags")
  echo $(echo $tag_json | cut -f 2 -d: | cut -f 1 -d,) | sed -e 's/^"//' -e 's/"$//'   
}

get_user_name () {
  local default=$(whoami)
  if [ -z "${username}" ]; then
    echo -n "Please enter the desired signing name (default: $default):"
    read username
    if [ -z "${username}" ]; then
      username=$default
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

        echo -e "${magenta}Gitian.sigs directory not found.${reset}"
        echo -n "Would you like to clone gitian.sigs to default directory(Y/N)? (default: Y):"
        read b_clone_default_sigs
        if [ -z "${b_clone_default_sigs}" ] || ([ ! -z "${b_clone_default_sigs}" ] && [[ "$b_clone_default_sigs" =~ ^([yY][eE][sS]|[yY])+$ ]]); then
            git clone ${base_repo}gitian.sigs.git "$path_to_gitian_sigs"
            break
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
############################ Functions ##################################


echo -e "${cyan}******************************************************************"
echo "****                                                          ****" 
echo "****     Welcome to the guided build of the Veil wallet!      ****" 
echo "****                                                          ****"
echo "******************************************************************"
echo "****                                                          ****" 
echo "****    This script uses Docker and Gitian to create Veil     ****"
echo "****   wallet binaries for the operating systems you select.  ****"
echo "****       Don't worry we will do most of the work. :)        ****"
echo "****                                                          ****" 
echo "****                  Let's get started!                      ****" 
echo "****                                                          ****" 
echo -e "******************************************************************${reset}"
echo "Checking for gpg..."
$THISDIR/gpg_program_check.sh
b_has_gpg=$?
if [[ $((b_has_gpg)) == ${b_has_gpg} ]]; then
    echo -e "${green}GPG installed!${reset}" 
else
    exit 1
fi

echo -n "Do you have a private key installed(Y/N)? (default: Y): "
read b_key_check
if [ ! -z "${b_key_check}" ] && [[ ! "$b_key_check" =~ ^([yY][eE][sS]|[yY])+$ ]] ; then
    echo -e "${magenta}Exiting -- A private key is required! Please install one an restart the script.${reset}"
    exit 1
fi

echo " " 
echo "******************************************************************"
echo "Checking for docker..."
which docker
if [ $? -eq 0 ]
then
    docker --version | grep "Docker version"
    if [ $? -eq 0 ]
    then
        echo -e "${green}Docker found!${reset}"  
        $THISDIR/remove_all_containers.sh       
        $THISDIR/remove_all_images.sh       
    else
     $THISDIR/docker_install.sh        
    fi
else
    $THISDIR/docker_install.sh  
fi
echo -e "${cyan} "
echo "******************************************************************"
echo "****               Operating System Selection                 ****"
echo -e "******************************************************************${reset}"
echo -n "Do you want to build for Linux(Y/N)? (default: Y): "
read build_linux_check
if [ ! -z "${build_linux_check}" ]; then
    if [[ ! "$build_linux_check" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        b_build_linux="N"
    fi
fi

echo -n "Do you want to build for OSX(Y/N)? (default: Y): "
read build_osx_check
if [ ! -z "${build_osx_check}" ]; then
    if [[ ! "$build_osx_check" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        b_build_osx="N"
    fi
fi

echo -n "Do you want to build for Windows(Y/N)? (default: Y): "
read build_win_check
if [ ! -z "${build_win_check}" ]; then
    if [[ ! "$build_win_check" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        b_build_windows="N"
    fi
fi

# If osx is selected check for the osx sdk
if [[ "$b_build_osx" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo -e "${cyan} "
    echo "******************************************************************"
    echo "****                       SDK Download                       ****"
    echo -e "******************************************************************${reset}"
    echo "Build for Mac selected. Checking for OSX SDK."
    if [[ ! -f "$THISDIR/cache/MacOSX10.11.sdk.tar.gz" ]]; then
        echo -n "MacOSX10.11.sdk.tar.gz does not exist in cache. Download if now(Y/N)? (default: Y):"
        read b_download_osx_sdk
        if ([ -z "${s_branch_or_tag}" ] || [[ "$b_download_osx_sdk" =~ ^([yY][eE][sS]|[yY])+$ ]]); then
            echo "Downloading MacOSX10.11.sdk.tar.gz to $THISDIR/cache/MacOSX10.11.sdk.tar.gz."
            cd ${THISDIR}/cache
            wget -O MacOSX10.11.sdk.tar.gz "https://www.dropbox.com/s/i6ytzweevpsb2ic/MacOSX10.11.sdk.tar.gz"
            cd ${THISDIR}
            echo -e "${green}MacOSX10.11.sdk.tar.gz Download load complete.${reset}"
        else
            echo "OSX SDK download skipped! OSX binaries will not be built!"
            b_build_osx="N"
        fi
    else
          echo -e "${green}MacOSX10.11.sdk.tar.gz found in cache!${reset}"
    fi  
fi
echo -e "${cyan} "
echo "******************************************************************"
echo "****                      Repo Selection                      ****"
echo -e "******************************************************************${reset}"
echo -n "Please enter the repo to pull code from? (default: ${wallet_repo}): "
read new_repo
if [ ! -z "${new_repo}" ]; then
    $base_repo=new_repo 
    $wallet_repo=$base_repo
fi
echo -e "${green}Selected repo: ${wallet_repo}${reset}"
echo -e "${cyan} "
echo "******************************************************************"
echo "****                   Branch/Tag Selection                   ****"
echo -e "******************************************************************${reset}"
fall_back_branch_or_tag="master"
branch_or_tag=""
if [ -z "${1}" ]; then
  echo "Getting the newest tag from Github..."
  branch_or_tag=`get_latest_tag`
  if [ -z "${branch_or_tag}" ]; then
    echo -e "${magenta}Could not get the latest remote tag from: ${wallet_repo}, therefore defaulting to building: ${fall_back_branch_or_tag}${reset}"
    branch_or_tag="${fall_back_branch_or_tag}"
  fi
else
  branch_or_tag="${1}"
fi
echo -n "Please enter a tag or branch to build (default: ${branch_or_tag}): "
read s_branch_or_tag
if [ ! -z "${s_branch_or_tag}" ]; then  
    branch_or_tag=$s_branch_or_tag
fi
echo -e "${green}Selected tag/branch: ${branch_or_tag}${reset}"
echo -e "${cyan} "
echo "******************************************************************"
echo "****                    Post build options                    ****"
echo -e "******************************************************************${reset}"
echo -n "Would you like to sign the manifests(Y/N)? (default: Y): "
read b_sign_manifests
if [ -z "${b_sign_manifests}" ] || ([ ! -z "${b_sign_manifests}" ] && [[ "$b_sign_manifests" =~ ^([yY][eE][sS]|[yY])+$ ]]); then
    get_user_name
    get_path_to_gitian_sigs  
else    
    echo -e "${magenta}WARNING: Moving, signing and pushing sigs will be skipped.${reset}"      
fi

IFS='-' read -r -a platforms <<< "$1"  

# Run the build
$THISDIR/build_veil.sh "${branch_or_tag}" "${wallet_repo}" "${platforms}" 

# Move and sign the manifest files
$THISDIR/move_and_sign_manifest.sh "$username" "$path_to_gitian_sigs"

if [[ "$branch_or_tag" =~ ^([vV]) ]]; then
    branch_or_tag="${branch_or_tag:1}"
fi

# Push the sigs to Github
$THISDIR/push_sigs.sh "$username" "$branch_or_tag" "$path_to_gitian_sigs"

