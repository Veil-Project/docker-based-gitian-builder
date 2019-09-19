#!bin/bash 

VERSION="master"
SIGNER="4x13"

get_input_from_user () {
    get_user_name
    get_path_to_gitian_sigs
}

get_input_from_user () {
    get_signer_name
    get_version
    get_path_to_gitian_sigs
}

SIGNER=
get_signer_name () {
  default=$(whoami)
  if [ -z "${SIGNER}" ]; then
    echo -n "Enter desired signing name (default: $default):"
    read SIGNER
    if [ -z "${SIGNER}" ]; then
      SIGNER=$default
    fi
  fi
}

VERSION=
get_version() {
  if [ -z "${VERSION}" ]; then
    echo -n "Enter desired version number (default: master):"
    read VERSION
    if [ -z "${VERSION}" ]; then
      VERSION="master"
    fi
  fi
}

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

check_for_gpg () {
  hash gpg 2>/dev/null || { echo >&2 "This script requires the 'gpg' program, it may not be installed or not on your path."; exit 1; }
}

check_for_gpg

get_input_from_user

cd ${path_to_gitian_sigs}

git add $VERSION-linux/$SIGNER
git add $VERSION-win/$SIGNER
git add $VERSION-osx/$SIGNER
git commit -a -m "Add $VERSION unsigned sigs for $SIGNER"
git pull --rebase origin master
git push


