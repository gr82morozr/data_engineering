#!/bin/bash -eu

#By using set -o pipefail, making the pipeline more strict in terms of error catching
set -o pipefail

ipvar="0.0.0.0"

# These should be set in the .env file
declare LinuxDR
declare WindowsDR
declare MacOSDR
declare COMPOSE

cp ../elk.env ./.env
source ./.env

HEADERS=(
  -H "kbn-version: ${ELK_VERSION}"
  -H "kbn-xsrf: kibana"
  -H 'Content-Type: application/json'
)


# Create the script usage menu
usage() {
  cat <<EOF | sed -e 's/^  //'
  usage: ./elastic-container.sh [-v] (stage|start|stop|restart|status|help)
  actions:
    stage     downloads all necessary images to local storage
    start     creates a container network and starts containers
    stop      stops running containers without removing them
    destroy   stops and removes the containers, the network, and volumes created
    restart   restarts all the stack containers
    status    check the status of the stack containers
    clear     clear all documents in logs and metrics indexes
    help      print this message
  flags:
    -v        enable verbose output
EOF
}

# Create a function to enable the Detection Engine and load prebuilt rules in Kibana
configure_kbn() {
  MAXTRIES=15
  i=${MAXTRIES}

  while [ $i -gt 0 ]; do
    STATUS=$(curl -I -k --silent "${LOCAL_KBN_URL}" | head -n 1 | cut -d ' ' -f2)
    echo
    echo "Attempting to enable the Detection Engine and install prebuilt Detection Rules."

    if [ "${STATUS}" == "302" ]; then
      echo
      echo "Kibana is up. Proceeding."
      echo
      output=$(curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPOST "${LOCAL_KBN_URL}/api/detection_engine/index")
      [[ ${output} =~ '"acknowledged":true' ]] || (
        echo
        echo "Detection Engine setup failed :-("
        exit 1
      )

      echo "Detection engine enabled. Installing prepackaged rules."
      curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPUT "${LOCAL_KBN_URL}/api/detection_engine/rules/prepackaged" 1>&2

      echo
      echo "Prepackaged rules installed!"
      echo
      if [[ "${LinuxDR}" -eq 0 && "${WindowsDR}" -eq 0 && "${MacOSDR}" -eq 0 ]]; then
        echo "No detection rules enabled in the .env file, skipping detection rules enablement."
        echo
        break
      else
        echo "Enabling detection rules"
        if [ "${LinuxDR}" -eq 1 ]; then

          curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST "${LOCAL_KBN_URL}/api/detection_engine/rules/_bulk_action" -d'
            {
              "query": "alert.attributes.tags: \"Linux\"",
              "action": "enable"
            }
            ' 1>&2
          echo
          echo "Successfully enabled Linux detection rules"
        fi
        if [ "${WindowsDR}" -eq 1 ]; then

          curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST "${LOCAL_KBN_URL}/api/detection_engine/rules/_bulk_action" -d'
            {
              "query": "alert.attributes.tags: \"Windows\"",
              "action": "enable"
            }
            ' 1>&2
          echo
          echo "Successfully enabled Windows detection rules"
        fi
        if [ "${MacOSDR}" -eq 1 ]; then

          curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X POST "${LOCAL_KBN_URL}/api/detection_engine/rules/_bulk_action" -d'
            {
              "query": "alert.attributes.tags: \"macOS\"",
              "action": "enable"
            }
            ' 1>&2
          echo
          echo "Successfully enabled MacOS detection rules"
        fi
      fi
      echo
      break
    else
      echo
      echo "Kibana still loading. Trying again in 40 seconds"
    fi

    sleep 40
    i=$((i - 1))
  done
  [ $i -eq 0 ] && echo "Exceeded MAXTRIES (${MAXTRIES}) to setup detection engine." && exit 1
  return 0
}

get_host_ip() {
  os=$(uname -s)
  if [ "${os}" == "Linux" ]; then
    ipvar=$(hostname -I | awk '{ print $1}')
  elif [ "${os}" == "Darwin" ]; then
    ipvar=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
  fi
}


create_folders() {
  # cleanup local folders
  rm -fr $ES_FOLDER/$ES_CLUSTER 2>/dev/null

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

}


set_fleet_values() {
  fingerprint=$(${COMPOSE} exec -w /usr/share/elasticsearch/config/certs/ca es-a1 cat ca.crt | openssl x509 -noout -fingerprint -sha256 | cut -d "=" -f 2 | tr -d :)
  printf '{"fleet_server_hosts": ["%s"]}' "https://fleet-svr:8220" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPUT "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/settings" -d @- | jq

  # set fleet-default-output
  printf '{"hosts": ["%s"]}' "https://es-a1:9200" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPUT "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/outputs/fleet-default-output" -d @- | jq
  printf '{"ca_trusted_fingerprint": "%s"}' "${fingerprint}" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPUT "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/outputs/fleet-default-output" -d @- | jq
  printf '{"config_yaml": "%s"}' "ssl.certificate_authorities: ['/usr/share/elastic-agent/certs/ca/ca.crt']" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPUT "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/outputs/fleet-default-output" -d @- | jq

  #create fleet_server policy
  FLEET_SERVER_POLICY_ID=$(printf '{"name": "%s", "description": "%s", "namespace": "%s", "monitoring_enabled": ["logs","metrics"], "inactivity_timeout": 1209600}' "Endpoint Policy" "" "default" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPOST "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/agent_policies?sys_monitoring=true" -d @- | jq -r '.item.id')


  pkg_version=$(curl -k --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XGET "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/epm/packages/endpoint" -d : | jq -r '.item.version')
 
 
  printf "{\"name\": \"%s\", \"description\": \"%s\", \"namespace\": \"%s\", \"policy_id\": \"%s\", \"enabled\": %s, \"inputs\": [{\"enabled\": true, \"streams\": [], \"type\": \"ENDPOINT_INTEGRATION_CONFIG\", \"config\": {\"_config\": {\"value\": {\"type\": \"endpoint\", \"endpointConfig\": {\"preset\": \"EDRComplete\"}}}}}], \"package\": {\"name\": \"endpoint\", \"title\": \"Elastic Defend\", \"version\": \"${pkg_version}\"}}" "Elastic Defend" "" "default" "${FLEET_SERVER_POLICY_ID}" "true" | curl -k --silent --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -XPOST "${HEADERS[@]}" "${LOCAL_KBN_URL}/api/fleet/package_policies" -d @- | jq

  export FLEET_SERVER_POLICY_ID

}

clear_documents() {
  if (($(curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X DELETE "https://es-a1:9200/_data_stream/logs-*" | grep -c "true") > 0)); then
    printf "Successfully cleared logs data stream"
  else
    printf "Failed to clear logs data stream"
  fi
  echo
  if (($(curl -k --silent "${HEADERS[@]}" --user "${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}" -X DELETE "https://es-a1:9200/_data_stream/metrics-*" | grep -c "true") > 0)); then
    printf "Successfully cleared metrics data stream"
  else
    printf "Failed to clear metrics data stream"
  fi
  echo
}

cleanup_containers() {
  ${COMPOSE} down
  ${COMPOSE} rm -f

}



# Logic to enable the verbose output if needed
OPTIND=1 # Reset in case getopts has been used previously in the shell.

verbose=0

while getopts "v" opt; do
  case "$opt" in
  v)
    verbose=1
    ;;
  *) ;;
  esac
done

shift $((OPTIND - 1))

[ "${1:-}" = "--" ] && shift

ACTION="${*:-help}"

if [ $verbose -eq 1 ]; then
  exec 3<>/dev/stderr
else
  exec 3<>/dev/null
fi

if docker compose >/dev/null; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null; then
  COMPOSE="docker-compose"
else
  echo "elastic-container requires docker compose!"
  exit 2
fi

case "${ACTION}" in

"stage")
  # Collect the Elastic, Kibana, and Elastic-Agent Docker images
  docker pull "docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}"
  docker pull "docker.elastic.co/kibana/kibana:${ELK_VERSION}"
  docker pull "docker.elastic.co/beats/elastic-agent:${ELK_VERSION}"
  ;;

"start")

  get_host_ip
  create_folders

  echo "Starting Elastic Stack network and containers."

  # created shared networks
  if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
    echo "The network $NETWORK_NAME already exists." | awk '{print "  "$0}'
  else
    docker network create --driver bridge $NETWORK_NAME | awk '{print "  "$0}'
    echo "The network $NETWORK_NAME created." | awk '{print "  "$0}'
  fi



  # check system config
  max_map_count=$(cat /proc/sys/vm/max_map_count)
  if [ "$max_map_count" -ne 262144 ]; then
    sudo sysctl -w vm.max_map_count=262144
  fi

  # start main elk cluster without fleet server
  cleanup_containers
  ${COMPOSE} up -d setup es-a1 es-a2 es-a3 kibana
  
  until curl -s -k ${LOCAL_KBN_URL}/login | grep '<script>'; 
    do sleep 5; 
    echo 1
  done;

  configure_kbn 1>&2 2>&3

  

  echo "Populating Fleet Settings."
  set_fleet_values > /dev/null 2>&1

  ${COMPOSE} up -d fleet-svr
  
  echo

  echo "READY SET GO!"
  echo
  echo "Browse to ${LOCAL_KBN_URL}"
  echo "Username: ${ELASTIC_USERNAME}"
  echo "Passphrase: ${ELASTIC_PASSWORD}"
  echo
  ;;

"stop")
  echo "Stopping running containers."

  ${COMPOSE} stop 
  ;;

"destroy")
  echo "#####"
  echo "Stopping and removing the containers, network, and volumes created."
  echo "#####"
  ${COMPOSE} down -v
  ;;

"restart")
  echo "#####"
  echo "Restarting all Elastic Stack components."
  echo "#####"
  ${COMPOSE} restart es-a1 es-a2 es-a3 kibana fleet-svr
  ;;

"status")
  ${COMPOSE} ps | grep -v setup
  ;;

"clear")
  clear_documents
  ;;

"help")
  usage
  ;;

*)
  echo -e "Proper syntax not used. See the usage\n"
  usage
  ;;
esac

# Close FD 3
exec 3>&-
