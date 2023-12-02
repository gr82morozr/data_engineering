#!/bin/bash
SPARK_VERSION=3.5.0
HADOOP_VERSION=3
SCALA_VERSION=2.13

mkdir -p ./notebooks

docker compose down

docker rm $(docker ps -aq)
docker rmi $(docker images -q) -f

docker build \
    --build-arg SPARK_VERSION=$SPARK_VERSION \
    --build-arg HADOOP_VERSION=$HADOOP_VERSION \
    --build-arg SCALA_VERSION=$SCALA_VERSION \
    -t spark-jupyterlab .  --no-cache

#docker run -d -p 8888:8888 --name spark spark-jupyterlab 
docker compose up -d
docker logs -f spark-master