ARG ELK_VERSION=latest
FROM docker.elastic.co/beats/filebeat:${ELK_VERSION}

USER root
RUN mkdir /usr/share/filebeat/input_data
RUN chmod 777 /usr/share/filebeat/input_data

VOLUME /usr/share/filebeat/input_data

COPY --chown=root:filebeat filebeat.yml /usr/share/filebeat/filebeat.yml
RUN chmod 744 /usr/share/filebeat/filebeat.yml