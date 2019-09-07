#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker run -it -h gitian_veil --name gitian_veil \
-v $THISDIR/cache:/shared/cache:Z \
-v $THISDIR/result:/shared/result:Z \
--entrypoint=/bin/bash \
gitian_veil -s
