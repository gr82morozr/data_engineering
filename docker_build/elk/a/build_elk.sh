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


# bring down services
source ./.env
check_and_stop_container filebeat
check_and_stop_container fleet
docker compose down --volumes --remove-orphans

# remove unused resources
docker image prune -f
docker network prune -f
docker volume prune -f


# Generate the .env file
source ../elk.env

# created shared networks
if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
  echo "The network $NETWORK_NAME already exists."
else
  docker network create --driver bridge $NETWORK_NAME
  echo "The network $NETWORK_NAME created."
fi



cat << EOF > ./.env
ELK_VERSION=$ELK_VERSION
ES_FOLDER=$ES_FOLDER
ES_CLUSTER=${ES_CLUSTER}_a
ELASTIC_PASSWORD=$ELASTIC_PASSWORD
KIBANA_PASSWORD=$KIBANA_PASSWORD
ES_HEAP_SIZE=$ES_HEAP_SIZE
LICENSE=$LICENSE
MEM_LIMIT=$MEM_LIMIT
EOF

source ./.env

# check system config
max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi


# cleanup local folders
rm -fr $ES_FOLDER/$ES_CLUSTER
check_result

# create local folders
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a1/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a1/logs
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a2/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a2/logs
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a3/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-a3/logs
mkdir -p $ES_FOLDER/$ES_CLUSTER/kibana/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/esagent/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/config/certs
mkdir -p $ES_FOLDER/$ES_CLUSTER/snapshots
check_result

# Optional
# Look for pther remote cluster to download CA
# make sure using same CA for remote cluster test

if [ ! -f ../shared/ca.zip ]; then
  source ./start.sh
  cp $ES_FOLDER/$ES_CLUSTER/config/certs/ca.zip ../shared/ca.zip
else
  mkdir -p $ES_FOLDER/$ES_CLUSTER/config/certs/ca
  cp ../shared/ca.zip $ES_FOLDER/$ES_CLUSTER/config/certs/ca.zip 
  source ./start.sh
fi  







