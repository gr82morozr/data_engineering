#!/bin/bash

# ====================================================
# Common functions
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

# created shared networks
create_network() {
  if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
    echo "The network $NETWORK_NAME already exists."
  else
    docker network create --driver bridge $NETWORK_NAME
    echo "The network $NETWORK_NAME created."
  fi
}


# ====================================================


# ====================================================
# Cleanup all running dockers
# ====================================================
# bring down services
source ./.env
docker compose down --volumes --remove-orphans

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



# ====================================================
# Init envs
# ====================================================

cp ./cluster.env ./.env
source ./.env

create_network

# ====================================================
# Elastic Cluster
# ====================================================

# check system config
max_map_count=$(cat /proc/sys/vm/max_map_count)
if [ "$max_map_count" -ne 262144 ]; then
  sudo sysctl -w vm.max_map_count=262144
fi



# cleanup local folders
echo Cleanup $CLUSTER_FOLDER/$ES_CLUSTER/
rm -fr $CLUSTER_FOLDER/$ES_CLUSTER
rm -fr $CLUSTER_FOLDER/$ES_CLUSTER
check_result

# create local folders
mkdir -p ${CLUSTER_FOLDER}/$ES_CLUSTER/es-a1/data
mkdir -p ${CLUSTER_FOLDER}/$ES_CLUSTER/es-a1/logs
mkdir -p ${CLUSTER_FOLDER}/$ES_CLUSTER/kibana/data
mkdir -p ${CLUSTER_FOLDER}/$ES_CLUSTER/esagent/data
mkdir -p ${CLUSTER_FOLDER}/$ES_CLUSTER/snapshots

check_result

# ====================================================
# MongoDB
# ====================================================
mkdir -p $CLUSTER_FOLDER/$MONGO_ROOT/data


# ====================================================
# Spark Cluster
# ====================================================
mkdir -p $CLUSTER_FOLDER/notebooks

docker rmi -f spark_kafka_img

docker build \
--build-arg SPARK_VERSION=$SPARK_VERSION    \
--build-arg HADOOP_VERSION=$HADOOP_VERSION  \
--build-arg SCALA_VERSION=$SCALA_VERSION    \
--build-arg KAFKA_VERSION=$KAFKA_VERSION    \
--build-arg SPARK_UID=$SPARK_UID            \
-f ./spark/Dockerfile.spark                       \
-t spark_kafka_img:1.0 .



# ====================================================
# Kafka Cluster
# ====================================================
mkdir -p ${CLUSTER_FOLDER}/${ZOOKEEPER_ROOT}/data

mkdir -p ${CLUSTER_FOLDER}/${KAFKA_ROOT}/config
mkdir -p ${CLUSTER_FOLDER}/${KAFKA_ROOT}/connect_config
mkdir -p ${CLUSTER_FOLDER}/${KAFKA_ROOT}/data
mkdir -p ${CLUSTER_FOLDER}/${KAFKA_ROOT}/log
mkdir -p ${CLUSTER_FOLDER}/${KAFKA_ROOT}/plugins


#download plugin JARs
wget https://repo1.maven.org/maven2/org/mongodb/kafka/mongo-kafka-connect/${KAFKA_MONGODB_CONNECTOR_VERSION}/mongo-kafka-connect-${KAFKA_MONGODB_CONNECTOR_VERSION}-all.jar \
     -O ${CLUSTER_FOLDER}/${KAFKA_ROOT}/plugins/mongo-kafka-connect-${KAFKA_MONGODB_CONNECTOR_VERSION}-all.jar
     



docker compose up -d
docker compose logs -f 

