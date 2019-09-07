#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker run -h gitian_veil --name gitian_veil \
-v $THISDIR/cache:/shared/cache:Z \
-v $THISDIR/result:/shared/result:Z \
gitian_veil
