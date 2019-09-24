#!/bin/bash

# doc: bash build_veil.sh {tag or branch} {repo url} {gbuild # of threads to use} {amount of memory to use}
# example: bash build_veil.sh v1.0.4.6 https://github.com/Veil-Project/veil 4 4096
# parameters: 
#   {tag or branch}: optional - defaults to master
#   {repo}: optional - defaults to https://github.com/Veil-Project/veil
#   {gbuild # of threads to use}: optional - defaults to 4 cores.
#   {amount of memory to use}: optional - defaults to
# This will build tag v1.0.4.6 from the https://github.com/Veil-Project/veil repo using 4 processor cores and 4096MB of memory.
# Creates Mac, Linux, Windows binaries, 32 and 64 bit as well as ARM.

green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
masterApiEndpoint="https://api.github.com"
repo="https://github.com/Veil-Project/veil"
num_procs=4
memory_size=4096

get_latest_tag () {
  local url="curl ${masterApiEndpoint}/repos/Veil-Project/veil/tags"
  response=(`${url} 2>/dev/null | sed -n 's/"name": "\(.*\)",$/\1/p'`)
  echo ${response[0]}
}

check_mac () {
  if [[ "${1}" == "osx" ]] && [[ ! -f "$THISDIR/cache/MacOSX10.11.sdk.tar.gz" ]]; then
    echo -e "${magenta}MacOSX10.11.sdk.tar.gz does not exist in cache therefore OSX build not available.${reset}"
    exit -1
  fi
}

num_procs=
get_num_procs () {
  if [[ $((3)) != ${3} ]]; then
      echo "System CPU cores: $nproc; Requesting to use $3 proc(s)"
      num_procs=${3}   
  fi

  # if requested procs more than the actual.
  if [[ num_procs -ge $nproc ]]; then
      echo "Too many cores requested: $3! System CPU cores: $nproc"
      num_procs=$nproc-1 
  fi
  echo "Gitian build will use $num_procs proc(s)"
}

memory_size=
get_memory_size () {
  total_system_memory=`free -m | grep Mem | awk '{print $2}'`

  if [[ $((4)) != ${4} ]]; then
      echo "System memory: $total_system_memory; Requesting to use $4"
      memory_size=${4}   
  fi
 # if requested procs more than the actual.
  if [[ memory_size -ge $total_system_memory ]]; then
      echo "Too much memory requested: $4! System memory: $total_system_memory"
      memory_size=$total_system_memory-2048 
  fi
  echo "Gitian build will use $memory_size MBs on memory"
}

fall_back_branch_or_tag="master"
branch_or_tag=
if [ -z "${1}" ]; then
  branch_or_tag=`get_latest_tag`
  if [ -z "${branch_or_tag}" ]; then
    echo -e  "${magenta}Could not get the latest remote tag from: ${masterRepo}, therefore defaulting to building: ${fall_back_branch_or_tag}${reset}"
    branch_or_tag="${1}"
  fi
else
  branch_or_tag="${1}"
fi

if [ -n "${2}" ]; then
  repo="${2}"
fi

$THISDIR/build_gitian_veil.sh

platforms=("osx" "win" "linux")

for platform in "${platforms[@]}"; do
  check_mac "${platform}"
  sdate=`date +%s`
  echo -e "${cyan}starting $platform build of tag: ${branch_or_tag} at: `date`${reset}"
  time docker run -h gitian_veil --name gitian_veil-$sdate \
  -v $THISDIR/cache:/shared/cache:Z \
  -v $THISDIR/result:/shared/result:Z \
  gitian_veil \
  "${branch_or_tag}" \
  "${repo}" \
  "../veil/contrib/gitian-descriptors/gitian-${platform}.yml" \
  "$num_procs" \ 
  "$memory_size"
done