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
check_and_stop_container metricbeat
check_and_stop_container filebeat
check_and_stop_container apm-svr
check_and_stop_container fleet-svr
check_and_stop_container agent
docker compose down --volumes --remove-orphans

# remove unused resources
docker image prune -f
docker network prune -f
docker volume prune -f


source ../elk.env
cp ../elk.env ./.env

source ./.env

# check system config
max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi


# cleanup local folders
echo Cleanup $ES_FOLDER/$ES_CLUSTER/
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







