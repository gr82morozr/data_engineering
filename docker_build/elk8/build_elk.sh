#!/bin/bash


# ====================================================

check_result() {
  # Check if the command failed
  if [ $? -ne 0 ]; then
    echo "script failed, exiting."
    exit 1
  fi
}

check_and_stop_container() {
  local container_name="$1"
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)" == "true" ]]; then
    echo "Container $container_name is running. Shutting it down..."
    docker stop "$container_name"
  else
    echo "Container $container_name is not running."
  fi
}
# ====================================================

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


# bring down services
check_and_stop_container filebeat
check_and_stop_container fleet
docker compose down --volumes --remove-orphans





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



