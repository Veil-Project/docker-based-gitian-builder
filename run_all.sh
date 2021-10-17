#!/bin/bash

# doc: sudo bash run_all.sh {repo} {tag} {signing-username} {gbuild # of threads to use} {amount of memory to use}
# example: sudo bash run_all.sh Veil-Project v1.0.4.6 codeofalltrades 4 4096
# parameters:
#   {repo} (optional): defaults to Veil-Project
#   {tag} (optional): defaults to highest number tag.
#   {gbuild # of threads to use} (optional): defaults to 4 cores.
#   {amount of memory to use} (optional): defaults to 4096
# This script will build tag v1.0.4.6 from the https://github.com/Veil-Project/veil repo using 4 processor cores and 4096MB of memory.
# It creates Mac, Linux, Windows binaries, 32 and 64 bit as well as ARM.

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

# Script variables 
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_master_api_endpoint="https://api.github.com"
_git_base_url="https://github.com"
_selected_repo="Veil-Project"

if [ ! -z "${1}" ]; then
    _selected_repo="${1}"
fi

_base_repo="${_git_base_url}/${_selected_repo}"
_wallet_repo="${_base_repo}/veil/"

_username=$SUDO_USER
_path_to_gitian_sigs=

# OS build flags
b_build_linux="Y"
b_build_osx="Y"
b_build_windows="Y"

############################ Functions ##################################
get_latest_tag () {
  tag_json=$(curl -s "${_master_api_endpoint}/repos/${_selected_repo}/veil/tags")
  echo $(echo $tag_json | cut -f 2 -d: | cut -f 1 -d,) | sed -e 's/^"//' -e 's/"$//'   
}

get_user_name () {
  if [ ! -z "${3}" ]; then
      _username="${3}"
  fi
  echo "Signing username: ${_username}"
}

get_path_to_gitian_sigs () {
  # Set the default path
  _path_to_gitian_sigs=../gitian.sigs

  # Check for the default path
  echo "Checking for gitian.sigs directory: ${_path_to_gitian_sigs}."
  if [ -d "${_path_to_gitian_sigs}" ]; then
      echo -e "${green}Gitian.sigs directory found.${reset}"
  else
      echo -e "${magenta}Gitian.sigs directory not found.${reset}"
      echo -e "${cyan}Cloning gitian.sigs to: ${_path_to_gitian_sigs}${reset}"
      git clone ${_base_repo}gitian.sigs.git "$_path_to_gitian_sigs"
  fi

  echo -e "${green}Gitian.sigs directory set to: ${_path_to_gitian_sigs}${reset}"
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
get_user_name
echo "Checking for gpg..."
$THISDIR/gpg_program_check.sh
b_has_gpg=$?
if [[ $((b_has_gpg)) == ${b_has_gpg} ]]; then
    echo -e "${green}GPG installed!${reset}" 
else
    exit 1
fi

echo "******************************************************************"
echo -e "${cyan}Checking for docker...${reset}"
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
echo "****                       SDK Download                       ****"
echo -e "******************************************************************${reset}"
echo "Build for Mac selected. Checking for OSX SDK."
if [[ ! -f "$THISDIR/cache/MacOSX10.11.sdk.tar.gz" ]]; then
    echo -n "MacOSX10.11.sdk.tar.gz does not exist in cache. Downloading it now:"
    echo "Downloading MacOSX10.11.sdk.tar.gz to $THISDIR/cache/MacOSX10.11.sdk.tar.gz."
    cd ${THISDIR}/cache
    wget -O MacOSX10.11.sdk.tar.gz "https://www.dropbox.com/s/i6ytzweevpsb2ic/MacOSX10.11.sdk.tar.gz"
    cd ${THISDIR}
    echo -e "${green}MacOSX10.11.sdk.tar.gz Download load complete.${reset}"
else
      echo -e "${green}MacOSX10.11.sdk.tar.gz found in cache!${reset}"
fi

echo -e "${cyan} "
echo "******************************************************************"
echo "****                      Repo Selection                      ****"
echo -e "******************************************************************${reset}"
echo -e "${green}Selected repo: ${_wallet_repo}${reset}"

echo -e "${cyan} "
echo "******************************************************************"
echo "****                   Branch/Tag Selection                   ****"
echo -e "******************************************************************${reset}"
fall_back_branch_or_tag="master"
branch_or_tag=""
if [ -z "${2}" ]; then
  echo "Getting the newest tag from Github..."
  branch_or_tag=`get_latest_tag`
  if [ -z "${branch_or_tag}" ]; then
    echo -e "${magenta}Could not get the latest remote tag from: ${_wallet_repo}, therefore defaulting to building: ${fall_back_branch_or_tag}${reset}"
    branch_or_tag="${fall_back_branch_or_tag}"
  fi
else
  branch_or_tag="${2}"
fi
echo -e "${green}Selected tag/branch: ${branch_or_tag}${reset}"
echo -e "${cyan} "
echo "******************************************************************"
echo "****                    Post build options                    ****"
echo -e "******************************************************************${reset}"
get_path_to_gitian_sigs

IFS='-' read -r -a platforms <<< "$1"  

# Run the build
$THISDIR/build_veil.sh "${branch_or_tag}" "${_wallet_repo}" "${platforms}"
echo -e "${green}Calling build_veil.sh branch_or_tag: ${branch_or_tag}; _wallet_repo: ${_wallet_repo}; platforms: ${platforms}; ${reset}"


# Move and sign the manifest files
#$THISDIR/move_and_sign_manifest.sh "_username" "$_path_to_gitian_sigs"

echo -e "Calling move_and_sign_manifest.sh ${green}_username: ${_username}; _path_to_gitian_sigs: ${_path_to_gitian_sigs}; ${reset}"

if [[ "$branch_or_tag" =~ ^([vV]) ]]; then
    branch_or_tag="${branch_or_tag:1}"
fi

# Push the sigs to Github
#$THISDIR/push_sigs.sh "_username" "$branch_or_tag" "$_path_to_gitian_sigs"
echo -e "Calling push_sigs.sh ${green}_username: ${_username}; branch_or_tag: ${branch_or_tag}; _path_to_gitian_sigs: ${_path_to_gitian_sigs}; ${reset}"


