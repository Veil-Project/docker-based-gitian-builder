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

get_tag_and_os() {
  echo ${1/veil-/}
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
  dir=$(get_build_name "${basename}")
  tagandos=$(get_tag_and_os "${dir}") 

  manifest_dir="${path_to_gitian_sigs}/${tagandos}/${user}"
  mkdir -p "${manifest_dir}"
  cp "${manifest}" "${manifest_dir}"

  # rename the file from res.yml to build.assert
  buildsigname=$(get_build_sig_name "${basename}")
  mv "${manifest_dir}/${basename}" "${manifest_dir}/${buildsigname}"

  #sign the file.
  manifest_file="${manifest_dir}/${buildsigname}"
  sign_manifest "${manifest_file}"

  #rename the signed file.
  signedfile="${manifest_file}.asc"
  mv "${signedfile}" "${signedfile/.asc/.sig}"

done

echo "Done! Please create a merge request back to gitian.sigs upstream."
© 2019 GitHub, Inc.
