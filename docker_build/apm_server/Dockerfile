FROM docker.elastic.co/apm/apm-server:${ELK_VERSION:-8.8.2}

USER root
# Update package list, install curl, and clean up
RUN apt update && apt install -y curl 

USER apm-server