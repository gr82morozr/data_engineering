#!/bin/bash

docker compose down -v --rmi all

max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi

# - generate .env
cat << EOF > .env
ELK_VERSION=7.17.1
ELK_CLUSTER=es7-cluster
ES_FOLDER=$PWD
EOF
source .env


rm -fr $ES_FOLDER/$ELK_CLUSTER

mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-1/data
mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-1/logs
mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-2/data
mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-2/logs
mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-3/data
mkdir -p $ES_FOLDER/$ELK_CLUSTER/node-3/logs

docker compose up -d

echo
echo ===========================================================
echo 
echo Elasticsearch : http://[ELK_CLUSTER_IP]:9200
echo
echo Kibana : http://[ELK_CLUSTER_IP]:5601
echo 
echo ===========================================================



