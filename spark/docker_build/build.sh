#!/bin/bash
export SPARK_VERSION=3.5.0
export HADOOP_VERSION=3
export SCALA_VERSION=2.13
export KAFKA_VERSION=3.6.0
export ZOOKEEPER_VERSION=3.9.1
export AKHQ_VERSION=0.24.0

export NETWORK_NAME=data-network

mkdir -p ./notebooks
#mkdir -p ./kafka_data
#chmod -R 777 ./kafka_data
docker compose down




docker rm $(docker ps -aq)
docker rmi $(docker images -q) -f


# created shared networks
if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
  echo "The network $NETWORK_NAME already exists."
else
  docker network create --driver bridge $NETWORK_NAME
  echo "The network $NETWORK_NAME created."
fi


docker build \
    --build-arg SPARK_VERSION=$SPARK_VERSION    \
    --build-arg HADOOP_VERSION=$HADOOP_VERSION  \
    --build-arg SCALA_VERSION=$SCALA_VERSION    \
    --build-arg KAFKA_VERSION=$KAFKA_VERSION    \
    -f ./Dockerfile.spark \
    -t spark-jupyterlab . 

#docker run -d -p 8888:8888 --name spark spark-jupyterlab 
docker compose up -d
docker logs -f kafka