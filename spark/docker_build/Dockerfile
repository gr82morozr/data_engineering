# Start from an Anaconda base image
FROM continuumio/anaconda3:latest

LABEL maintainer="gr82morozr@gmail.com"


# Set environment variables 
ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG SCALA_VERSION
ENV SPARK_HOME=/opt/spark

# For root
USER root
RUN apt-get update
RUN apt-get install -y curl wget openjdk-11-jdk
RUN useradd -m spark
RUN mkdir -p $SPARK_HOME

COPY ./start-master.sh /opt/spark
RUN chown -R spark:spark $SPARK_HOME
RUN chmod 777 /opt/spark/start-master.sh


# Switch to spark
USER spark

# Create a new environment and initialize it
#RUN conda create -n py310 python=3.10 && conda init bash

# Set the environment variable for the conda environment
#ENV PATH /home/spark/.conda/envs/py310/bin:$PATH
#ENV CONDA_DEFAULT_ENV py310

RUN /bin/bash -c "pip install --upgrade pip"
RUN /bin/bash -c "pip install pyspark"
RUN /bin/bash -c "pip install jupyterlab --upgrade"

# Update PATH for Spark
ENV PATH="$SPARK_HOME/bin:$PATH"
RUN mkdir -p /home/spark/notebooks
# Download and install Spark
                                                              
RUN /bin/bash -c "wget https://dlcdn.apache.org/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION-scala$SCALA_VERSION.tgz -O /tmp/spark.tgz"
RUN /bin/bash -c "cd /tmp && tar zxvf /tmp/spark.tgz"
RUN /bin/bash -c "mv /tmp/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION-scala$SCALA_VERSION/*  $SPARK_HOME"
RUN /bin/bash -c "wget https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_${SCALA_VERSION}/${SPARK_VERSION}/spark-sql-kafka-0-10_${SCALA_VERSION}-${SPARK_VERSION}.jar -O $SPARK_HOME/jars/spark-sql-kafka-0-10_${SCALA_VERSION}-${SPARK_VERSION}.jar"
RUN /bin/bash -c "cp $SPARK_HOME/jars/spark-sql-kafka-0-10_${SCALA_VERSION}-${SPARK_VERSION}.jar $SPARK_HOME/jars/spark-kafka-connector.jar"

# Update conda
# RUN conda update -n base -c defaults conda -y 
# RUN conda install -c conda-forge jupyterlab

ENV JUPYTER_TOKEN=""
ENV JUPYTER_PASSWORD=""
ENV JUPYTER_ENABLE_LAB=yes

