#!/bin/bash

docker stop $(docker ps -aq)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -aq)

max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi

export ELK_VERSION=8.8.1
export ES_FOLDER=$PWD
export ELASTIC_PASSWORD=password
export KIBANA_PASSWORD=password
export CLUSTER_NAME=elk8-cluster
export LICENSE=basic
export ES_PORT=9200
export KIBANA_PORT=5601
export MEM_LIMIT=2147483648

rm -fr $ES_FOLDER/node-1
rm -fr $ES_FOLDER/node-2
rm -fr $ES_FOLDER/node-3

mkdir -p $ES_FOLDER/node-1/data
mkdir -p $ES_FOLDER/node-1/logs
mkdir -p $ES_FOLDER/node-2/data
mkdir -p $ES_FOLDER/node-2/logs
mkdir -p $ES_FOLDER/node-3/data
mkdir -p $ES_FOLDER/node-3/logs

docker-compose up -d


# password=""

# while [ -z "$password" ]; do
#     sleep 3
#     output=$(docker exec -it es-node-1 /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b)
#     password=$(echo "$output" | grep -oP 'New value: \K.*')
#     #echo "[elastic] password: $password"
# done

# echo "[elastic] password: $password"
