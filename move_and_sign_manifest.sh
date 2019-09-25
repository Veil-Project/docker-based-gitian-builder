#!/bin/bash

# doc: bash move_and_sign_manifest.sh {signer} {path to gitian sigs} {easysigning}
# example: bash move_and_sign_manifest.sh "4x13" "../gitian.sigs" --easysigning
# parameters: 
#   {signer} (optional): defaults to "4x13"
#   {path to gitian sigs} (optional): defaults to ../gitian.sigs
#   {easysigning} (optional): defaults to true
# This script will sign the sign the mainifest files created by the gitian build.
# The mainifest and signature files will be move to the gitian sigs path.
# A text file, SHASUM256, containing the build hashes will be created and stored in the gitian build output folder(/result/out/)
# You will be prompted for any parameters you don't submit via the cmd line.

# Constants
green="\033[38;5;40m"
magenta="\033[38;5;200m"
cyan="\033[38;5;87m"
reset="\033[0m"

# Script variables 
path_to_gitian_sigs=""
easysigning=true
signer="4x13"
output_hashes="result/out/SHASUM256"
base_repo="https://github.com/Veil-Project/"

echo -e "${cyan} "
echo "******************************************************************"
echo "****                     Signing Manifest                     ****"
echo -e "******************************************************************${reset}"


############################ Functions ##################################
get_input_from_user () {
  get_signer_name
  get_path_to_gitian_sigs
}

process_args () {
  if [ ! -z "${1}" ]; then
    signer=${1}
  fi
  if [ ! -z "${2}" ]; then
    path_to_gitian_sigs=${2}
  fi
  if [[ -n "${3}" ]] && [[ "${3}" == "--easysigning" ]]; then
    easysigning=true
  elif [[ -n "${3}" ]] && [[ "${3}" == "-h" || "${3}" == "--help" ]]; then
    echo "usage: move_and_signing_manifest.sh [--easysigning]"
    echo ""
    echo "--easysigning allows you to type your gpg private key passphrase once to sign multiple manifest files."
    exit 0
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
            git clone "${base_repo}gitian.sigs.git" "$path_to_gitian_sigs"
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

get_build_name () {
  echo ${1/-res.yml/}
}

get_build_sig_name() {
  echo ${1/res.yml/build.assert}
}

check_for_gpg () {
  hash gpg 2>/dev/null || { echo >&2 "This script requires the 'gpg' program, it may not be installed or not on your path."; exit 1; }
}

passphrase=
sign_manifest () {
  if [[ "${easysigning}" = true ]] && [[ -z "${passphrase}" ]]; then
    echo -n "Please enter your passphrase for default gpg public key (never use this on a multi-user system): "
    read -s passphrase
    echo ""
  fi
  echo "Attempting to sign manifest: ${1}"
  if [ -n "${passphrase}" ]; then
    gpg --batch --yes -b --armor --passphrase "${passphrase}" "${1}"
  else
    gpg -b --armor "${1}"
  fi
}

get_build_hashes(){
    declare -A arr
    i=0
    while read key value; do
        if [[ "$value" =~ in_manifest ]] ; then
            break
        fi
        if ([[ ! "$value" =~ out_manifest ]] && [[ ! "$value" =~ !!omap ]]); then
            arr["$i"]="$key $value"
            i=$((i+1))
        fi  
    done < "$1"
    printf "%s\n" "${arr[@]}" >> $output_hashes
}
############################ Functions ##################################


### Main ###
process_args $1 $2 $3

check_for_gpg

get_input_from_user

for manifest in result/*.yml; do 
  echo -e "${cyan}Staring to process manifest: $manifest${reset}"
  
  basename=`basename $manifest` 
  buildname=$(get_build_name "${basename}")

  # split the build and version information.
  IFS='-' read -r -a buildparams <<< "$buildname"  
  buildparamcnt=${#buildparams[@]}

  tagversion="1.0.0.99"
  osversion="linux"

  # get the version and os information.
  if [[ buildparamcnt -ge 3 ]]; then
    tagversion="${buildparams[2]}"
    osversion="${buildparams[1]}"
  elif [[ buildparamcnt -ge 2 ]]; then
     tagversion="${buildparams[1]}"
  fi
  versionfoldername="${tagversion}-${osversion}"

  # Create the new sigs folders if need. 
  manifest_dir="${path_to_gitian_sigs}/${versionfoldername}/${signer}"
  if [ ! -d "${manifest_dir}" ]; then
    mkdir -p "${manifest_dir}"
  fi
  cp "${manifest}" "${manifest_dir}"

  # rename the files in the manifest_dir from res.yml to build.assert
  for file in ${manifest_dir}/*; do mv "$file" "$(get_build_sig_name "${file}")"; done
  
  #sign the file.
  buildsigname=$(get_build_sig_name "${basename}")
  manifest_file="${manifest_dir}/${buildsigname}"
  sign_manifest "${manifest_file}"

  #rename the signed file.
  for file in ${manifest_dir}/*.asc; do mv "$file" "${file/.asc/.sig}"; done

  #add the build hashes to the SHASUM256 file
  echo "Adding build hashes to the SHASUM256 file"
  get_build_hashes $manifest 
done

echo -e "${green}Signing complete.${reset}"

echo "Cleaning up the SHASUM256 file"
awk '!seen[$0]++' $output_hashes > "$output_hashes-new"
rm $output_hashes 
mv  "$output_hashes-new" $output_hashes

echo -e "${green}Done! Please create a merge request back to gitian.sigs upstream.${reset}"
