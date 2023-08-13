#!/bin/bash

source ./.env

# check system config
max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi



docker compose  up -d


echo
echo ===========================================================
echo 
echo "ELK Cluster : ${ES_CLUSTER} ( Version : ${ELK_VERSION} )"
echo 
echo "Elasticsearch : https://[ELK_CLUSTER_IP]:9200"
echo "elastic/$ELASTIC_PASSWORD"
echo
echo "Kibana : http://[ELK_CLUSTER_IP]:5601"
echo "elastic/$KIBANA_PASSWORD"
echo 
echo ===========================================================

docker logs -f setup

