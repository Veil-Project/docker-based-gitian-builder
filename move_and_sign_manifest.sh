#!/bin/bash

easysigning=true
process_args () {
  if [[ -n "${1}" ]] && [[ "${1}" == "--easysigning" ]]; then
    easysigning=true
  elif [[ -n "${1}" ]] && [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
    echo "usage: move_and_signing_manifest.sh [--easysigning]"
    echo ""
    echo "--easysigning allows you to type your gpg private key passphrase once to sign multiple manifest files."
    exit 0
  fi
}

get_input_from_user () {
  get_user_name
  get_path_to_gitian_sigs
}

user=
get_user_name () {
  default=$(whoami)
  if [ -z "${user}" ]; then
    echo -n "Enter desired signing name (default: $default):"
    read user
    if [ -z "${user}" ]; then
      user=$default
    fi
  fi
}

path_to_gitian_sigs=

get_path_to_gitian_sigs () {
  if [ -z "${path_to_gitian_sigs}" ]; then
    while [ 1 ]; do
      echo -n "Path to gitian.sigs directory (default: ./gitian.sigs): "
      read path_to_gitian_sigs
      if [ -z "${path_to_gitian_sigs}" ]; then
        path_to_gitian_sigs=./gitian.sigs
      fi
      if [ ! -d "${path_to_gitian_sigs}" ]; then
        echo "path: ${path_to_gitian_sigs} does not exist."
      else
        break
      fi
    done
  fi
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

for manifest in result/*.yml; do

  process_args $1

  check_for_gpg

  get_input_from_user

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

  # Create the new sigs folders. 
  manifest_dir="${path_to_gitian_sigs}/${versionfoldername}/${user}"
  mkdir -p "${manifest_dir}"
  cp "${manifest}" "${manifest_dir}"

  # rename the files in the manifest_dir from res.yml to build.assert
  for file in ${manifest_dir}/*; do mv "$file" "$(get_build_sig_name "${file}")"; done
  
  #sign the file.
  buildsigname=$(get_build_sig_name "${basename}")
  manifest_file="${manifest_dir}/${buildsigname}"
  sign_manifest "${manifest_file}"

  #rename the signed file.
  for file in ${manifest_dir}/*.asc; do mv "$file" "${file/.asc/.sig}"; done

done

echo "Done! Please create a merge request back to gitian.sigs upstream."
© 2019 GitHub, Inc.