#!/bin/bash
export SPARK_VERSION=3.5.0
export HADOOP_VERSION=3
export SCALA_VERSION=2.13
export KAFKA_VERSION=3.6.0

mkdir -p ./notebooks
mkdir -p ./kafka_data

docker compose down

docker rm $(docker ps -aq)
docker rmi $(docker images -q) -f

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