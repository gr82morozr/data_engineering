#!/bin/bash

docker stop $(docker ps -aq)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -aq)

max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi

export ELK_VERSION=7.17.1

export ES_FOLDER=$PWD

rm -fr $ES_FOLDER/node-data-1
rm -fr $ES_FOLDER/node-data-2
rm -fr $ES_FOLDER/node-data-3

mkdir -p $ES_FOLDER/node-data-1
mkdir -p $ES_FOLDER/node-data-2
mkdir -p $ES_FOLDER/node-data-3

docker compose up -d




