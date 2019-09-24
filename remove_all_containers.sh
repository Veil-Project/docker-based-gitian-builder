#!/bin/bash

docker ps -a | awk 'FNR > 1 {system("docker rm " $1)}' #FNR > 1 to skip the header row.

