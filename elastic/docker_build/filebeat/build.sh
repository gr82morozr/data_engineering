#!/usr/bin/bash

timestamp=$(date +'%Y-%m-%d_%H%M%S')

source ../elk/elk.env
# clean up folders

export ELK_VERSION=$ELK_VERSION

docker compose down


mkdir -p certs
cp  /home/user1/apps/elasticsearch/docker_build/elk/a/elk-cluster_a/config/certs/ca/ca.crt ./certs/ca.crt


docker compose up -d

docker logs -f filebeat
