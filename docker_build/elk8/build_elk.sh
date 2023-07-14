#!/bin/bash

check_result() {
  # Check if the command failed
  if [ $? -ne 0 ]; then
    echo "script failed, exiting."
    exit 1
  fi
}



# bring down services
# docker compose down -v --rmi all
docker compose down -v 

# - generate .env
cat << EOF > .env
ELK_VERSION=8.8.2
ES_FOLDER=$PWD
CLUSTER_NAME=elk8-cluster
ELASTIC_PASSWORD=password
KIBANA_PASSWORD=password
LICENSE=basic
MEM_LIMIT=2147483648
EOF

source ./.env


# check system config
max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi


# cleanup local folders
rm -fr $ES_FOLDER/$CLUSTER_NAME
check_result

# create local folders
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-1/data
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-1/logs
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-2/data
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-2/logs
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-3/data
mkdir -p $ES_FOLDER/$CLUSTER_NAME/es-node-3/logs
mkdir -p $ES_FOLDER/$CLUSTER_NAME/kibana/data
mkdir -p $ES_FOLDER/$CLUSTER_NAME/esagent/data
mkdir -p $ES_FOLDER/$CLUSTER_NAME/config/certs
check_result

docker compose up -d

echo
echo ===========================================================
echo 
echo Elasticsearch : https://[ELK_CLUSTER_IP]:9200
echo  elastic/$ELASTIC_PASSWORD
echo
echo Kibana : http://[ELK_CLUSTER_IP]:5601
echo  elastic/$KIBANA_PASSWORD
echo 
echo ===========================================================

docker logs -f setup


# password=""

# while [ -z "$password" ]; do
#     sleep 3
#     output=$(docker exec -it es8-node-1 /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b)
#     password=$(echo "$output" | grep -oP 'New value: \K.*')
#     #echo "[elastic] password: $password"
# done

# echo "[elastic] password: $password"
