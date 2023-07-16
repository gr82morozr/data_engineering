#!/bin/bash

source ./.env

docker compose up -d


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

