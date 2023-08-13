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
#docker network prune -f
#docker volume prune 


# Generate the .env file
source ../elk.env


cat << EOF > ./.env
ELK_VERSION=$ELK_VERSION
ES_FOLDER=$ES_FOLDER
ES_CLUSTER=${ES_CLUSTER}_b
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
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-b1/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/es-b1/logs
mkdir -p $ES_FOLDER/$ES_CLUSTER/kibana/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/esagent/data
mkdir -p $ES_FOLDER/$ES_CLUSTER/config/certs
mkdir -p $ES_FOLDER/$ES_CLUSTER/snapshots
check_result

source ./start.sh


