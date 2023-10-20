#!/usr/bin/bash

timestamp=$(date +'%Y-%m-%d_%H%M%S')

source ../elk/elk.env
# clean up folders

export ELK_VERSION=$ELK_VERSION

docker compose down

