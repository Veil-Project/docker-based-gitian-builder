#!/bin/bash

# doc: bash build_veil.sh {tag or branch} {repo url} {operating systems to build} {gbuild # of threads to use} {amount of memory to use} 
# example: bash build_veil.sh v1.0.4.6 https://github.com/Veil-Project/veil osx-win-linux 4 4096 
# parameters: 
#   {tag or branch} (optional): defaults to master
#   {repo url} (optional): defaults to https://github.com/Veil-Project/veil
#   {operating systems to build} (optional): defaults to osx-win-linux
#   {gbuild # of threads to use} (optional): defaults to 4 cores.
#   {amount of memory to use} (optional): defaults to 4096
# This script will build tag v1.0.4.6 from the https://github.com/Veil-Project/veil repo using 4 processor cores and 4096MB of memory.
# It creates Mac, Linux, Windows binaries, 32 and 64 bit as well as ARM.
# You will be prompted for any parameters you don't submit via the cmd line.

# Bash formatting.
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
repo="https://github.com/Veil-Project/veil"
platforms=("osx" "win" "linux")

# gbuild options
num_procs=4
memory_size=4096

fall_back_branch_or_tag="master"
branch_or_tag=
if [ -z "${1}" ]; then  
  echo -e "${magenta}No branch or tag specified: ${masterRepo}, therefore defaulting to building: ${fall_back_branch_or_tag}${reset}"
  branch_or_tag="${1}" 
else
  branch_or_tag="${1}"
fi

if [ -n "${2}" ]; then
  repo="${2}"
fi
echo -e "${cyan} "
echo "******************************************************************"
echo "****                Gitian build thread count                 ****"
echo -e "******************************************************************${reset}"
echo "System CPU cores: $(nproc)"
if [ -n "${4}" ]; then
  if [[ $((4)) != ${4} ]]; then       
      num_procs=${4}   
  fi
else
  echo -n "How many processors do you want to allocate to the gitian build? (default: $num_procs): "
  read b_proc_request
  if [ ! -z "${b_proc_request}" ]; then
    if [[ $((b_proc_request)) == ${b_proc_request} ]]; then       
        num_procs=${b_proc_request}   
    fi
  fi
fi
echo "Requesting to use $num_procs proc(s)"

# if requested procs more than the actual.
if [[ num_procs -ge $(nproc) ]]; then
    echo -e "${magenta}Too many cores requested: $num_procs! System CPU cores: $(nproc) ${reset}"
    num_procs=$(($(nproc)-1))
fi
echo -e "${green}Gitian build will use $num_procs proc(s)${reset}"

echo -e "${cyan} "
echo "******************************************************************"
echo "****                Gitian build memory amount                ****"
echo -e "******************************************************************${reset}"
total_system_memory=`free -m | grep Mem | awk '{print $2}'`
echo "System memory (free): $total_system_memory"
if [ -n "${5}" ]; then
  if [[ $((5)) != ${5} ]]; then      
      memory_size=${5}  
  fi 
else
  echo -n "How much memory do you want to allocate to the gitian build? (default: $memory_size): "
  read b_memory_request
  if [ ! -z "${b_memory_request}" ]; then
    if [[ $((b_memory_request)) == ${b_memory_request} ]]; then       
        memory_size=${b_memory_request}   
    fi
  fi
fi
echo -e "Requesting to use $memory_size MBs of memory";
# if requested memory is more than the actual.
if [[ memory_size -ge $total_system_memory ]]; then
    echo -e "${magenta}Too much memory requested: ${memory_size}! System memory: ${total_system_memory} ${reset}"
    memory_size=$((total_system_memory-2048))
fi
echo "Gitian build will use $memory_size MBs on memory"

# Parse the OS's from the cmd arg into an array.
if [ -n "${5}" ]; then
  IFS=' ' read -r -a platforms <<< "$5"
fi

echo -e "${cyan} "
echo "******************************************************************"
echo "****            Creating Docker Image and Container           ****"
echo -e "******************************************************************${reset}"
$THISDIR/build_gitian_veil.sh
echo -e "${green}Finsihed creating images and containter.${reset}"

echo -e "${cyan} "
echo "******************************************************************"
echo "****                   Starting Wallet Build                  ****"
echo -e "******************************************************************${reset}"
for platform in "${platforms[@]}"; do
  sdate=`date +%s`
  echo -e "${green}Starting $platform build of tag: ${branch_or_tag} at: `date`${reset}"
  sudo time docker run -h gitian_veil --name gitian_veil-$sdate \
  -v $THISDIR/cache:/shared/cache:Z \
  -v $THISDIR/result:/shared/result:Z \
  gitian_veil \
  "${branch_or_tag}" \
  "${repo}" \
  "../veil/contrib/gitian-descriptors/gitian-${platform}.yml" "$num_procs" "$memory_size"
done

echo -e "${green} " 
echo "******************************************************************"
echo "****                  Wallet builds complete                  ****"
echo -e "******************************************************************${reset}"
