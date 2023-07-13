#!/bin/bash

docker compose up -d

echo
echo ===========================================================
echo 
echo Elasticsearch : http://[ELK_CLUSTER_IP]:9200
echo
echo Kibana : http://[ELK_CLUSTER_IP]:5601
echo 
echo ===========================================================



