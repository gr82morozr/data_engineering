#!/bin/bash
echo "================================================"
echo  "Setting up Fleet server ... "
echo "================================================"


init_script() {

  cp ../elk/a/.env .

  source ./.env

  export ELK_VERSION
  export ES_CLUSTER
  export ELASTIC_PASSWORD
  export KIBANA_PASSWORD

  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  FLEET_SERVER_POLICY=fleet-server-policy-${TIMESTAMP}
  FLEET_SERVER_SERVICE_TOKEN_NAME=fleet-server-service_toekn-${TIMESTAMP}

  export FLEET_SERVER_POLICY
  export FLEET_SERVER_SERVICE_TOKEN_NAME
}


cleanup_env() {
  source ./.env

  # shutdown existing containers
  docker compose down
  docker compose -f ./docker-compose.agent.yml down

  docker rm fleet-svr
  docker rm agent

  # cleanup files
  rm -fr certs
  mkdir -p certs
  
  ES_FOLDER=../elk/elk.env

  cp  ../elk/elk.env ./.env
  source ./.env
  cp  ../elk/a/$ES_CLUSTER/config/certs/ca/ca.crt ./certs/ca.crt
  cp  ../elk/a/$ES_CLUSTER/config/certs/fleet-svr/fleet-svr.key ./certs/fleet-svr.key
  cp  ../elk/a/$ES_CLUSTER/config/certs/fleet-svr/fleet-svr.crt ./certs/fleet-svr.crt
}


create_service_token() {
  echo
  echo ================================================
  echo  Step 1 - create service token
  echo

  SERVICE_TOKEN=$(curl -s --cacert ./certs/ca.crt -u elastic:${ELASTIC_PASSWORD} --request POST https://es-a1:9200/_security/service/elastic/fleet-server/credential/token/${FLEET_SERVER_SERVICE_TOKEN_NAME} |  jq -r '.token.value' ) 
  export SERVICE_TOKEN
  echo "SERVICE_TOKEN=${SERVICE_TOKEN}" >> ./.env
  echo
}

create_fleet_server_policy() {
  echo
  echo ================================================
  echo  Step 3 - create fleet server policy
  echo

  FLEET_SERVER_POLICY_ID=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} --request POST \
    --url https://kibana:5601/api/fleet/agent_policies?sys_monitoring=true \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true' \
    --data "{\"name\":\"${FLEET_SERVER_POLICY}\", \"description\":\"Fleet Server Policy @ ${TIMESTAMP}.\", \"namespace\":\"default\",\"monitoring_enabled\":[\"logs\",\"metrics\"], \"is_default_fleet_server\": \"true\"}" |  jq -r '.item.id')
  
  export FLEET_SERVER_POLICY_ID
  export FLEET_SERVER_POLICY
  echo "FLEET_SERVER_POLICY=${FLEET_SERVER_POLICY}" >> ./.env
  echo "FLEET_SERVER_POLICY_ID=${FLEET_SERVER_POLICY_ID}" >> ./.env
  echo
}


get_enrollment_token() {
  echo
  echo ================================================
  echo  Step 3.5 - get enrolment token
  echo

  FLEET_SERVER_ENROLLMENT_TOKEN=$(curl -s -k --request GET \
  --url 'https://kibana:5601/api/fleet/enrollment_api_keys' \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: xx'   \
  -u elastic:password | jq --arg POLICY_ID "$FLEET_SERVER_POLICY_ID" -r '.items[] | select(.policy_id == $POLICY_ID) | .api_key')

  export FLEET_SERVER_ENROLLMENT_TOKEN
  echo "FLEET_SERVER_ENROLLMENT_TOKEN=${FLEET_SERVER_ENROLLMENT_TOKEN}" >> ./.env
  echo
}



add_fleet_server_integration_to_policy() {
  echo
  echo ================================================
  echo  Step 3 - Adding Fleet server integration 
  echo
   
  response=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} --request POST \
    --url https://kibana:5601/api/fleet/package_policies \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true' \
    --data "{
            \"policy_id\": \"${FLEET_SERVER_POLICY_ID}\",
            \"package\": {
                \"name\": \"fleet_server\",
                \"version\": \"1.2.0\"
            },
            \"name\": \"fleet_server\",
            \"description\": \"\",
            \"namespace\": \"default\",
            \"inputs\": {
                \"fleet_server-fleet-server\": {
                \"enabled\": true,
                \"vars\": {
                    \"host\": \"fleer-svr\",
                    \"port\": [
                    8220
                    ],
                    \"custom\": \"\"
                },
                \"streams\": {}
                }
            }
        }"
     )

  if echo $response | grep --silent 'already exists'; then
      echo 'already exists';
      return 0
  fi

  if echo $response | grep --silent 'error'; then
    echo 'failed'
    echo "$response"
    exit 1
  fi
 
}

add_server_host() {
  echo
  echo ================================================
  echo  Step 4 - Adding Fleet server host
  echo

  echo -n 'Checking if Fleet server host exists... '

  response=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} \
    --request GET \
    --url https://kibana:5601/api/fleet/fleet_server_hosts/fleet-server \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true')

  echo $response

  if ! echo $response | grep --silent 'Not Found'; then
    echo 'already exists'
    return 0
  fi


  echo -n 'Adding Fleet server host... '

  response=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} \
    --request POST \
    --url https://kibana:5601/api/fleet/fleet_server_hosts \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true' \
    --data '
      {
            "id": "fleet-svr",
            "name": "my-fleet-svr",
            "is_default": true,
            "host_urls": [
              "https://fleet-svr:8220"
            ]
      }')

  if echo $response | grep --silent 'error'; then
    echo 'failed'
    echo "$response"
    exit 1
  fi

}

set_output() {
  echo
  echo ================================================
  echo  Step 4 - Setting agent output location
  echo

  response=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} \
    --request PUT \
    --url https://kibana:5601/api/fleet/outputs/fleet-default-output \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true' \
    --data "
        {
          \"name\": \"default\",
          \"type\": \"elasticsearch\",
          \"is_default\": true,
          \"is_default_monitoring\": true,
          \"hosts\": [ \"https://es-a1:9200\" ],
          \"config_yaml\": \"ssl.certificate_authorities: ['/usr/share/elastic-agent/certs/ca.crt']\"
        }")

    if echo "$response" | grep --silent 'document already exists'; then
        echo 'already exists'
        return 0
    fi

    if echo $response | grep --silent 'error'; then
        echo 'failed'
        echo "$response"
        exit 1
    fi

    echo 'success'



}


init_script
cleanup_env


create_service_token
create_fleet_server_policy
get_enrollment_token
add_fleet_server_integration_to_policy
add_server_host
set_output



echo "Press any key to continue..."
read -n1 -s


docker compose  up -d 2>&1 | awk '{print "  "$0}'

docker logs -f fleet-svr | awk '{print "  "$0}'