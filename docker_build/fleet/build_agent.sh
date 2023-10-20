#!/bin/bash
echo "================================================"
echo  "Setting up Elastic Agent... "
echo "================================================"


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
source ./.env
AGENT_POLICY="Agent Policy Demo 1"


create_agent_policy() {
  echo
  echo ================================================
  echo  Step 3 - create agent policy
  echo

  AGENT_POLICY_ID=$(curl -s --cacert ./certs/ca.crt -u elastic:${KIBANA_PASSWORD} --request POST \
    --url https://kibana:5601/api/fleet/agent_policies?sys_monitoring=true \
    --header 'content-type: application/json' \
    --header 'kbn-xsrf: true' \
    --data "{\"name\":\"${AGENT_POLICY}\", \"description\":\"Agent Policy @ ${TIMESTAMP}.\", \"namespace\":\"default\",\"monitoring_enabled\":[\"logs\",\"metrics\"], \"is_default_fleet_server\": \"false\"}" |  jq -r '.item.id')
  
  export AGENT_POLICY_ID
  export AGENT_POLICY
  echo "AGENT_POLICY=${AGENT_POLICY}" >> ./.env
  echo "AGENT_POLICY_ID=${AGENT_POLICY_ID}" >> ./.env
  echo
}


get_enrollment_token() {
  echo
  echo ================================================
  echo  Step 3.5 - get enrolment token
  echo

  AGENT_ENROLLMENT_TOKEN=$(curl -s -k --request GET \
  --url 'https://kibana:5601/api/fleet/enrollment_api_keys' \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: xx'   \
  -u elastic:password | jq --arg POLICY_ID "$AGENT_POLICY_ID" -r '.items[] | select(.policy_id == $POLICY_ID) | .api_key')

  export AGENT_ENROLLMENT_TOKEN
  echo "AGENT_ENROLLMENT_TOKEN=${AGENT_ENROLLMENT_TOKEN}" >> ./.env
  echo
}





docker compose -f ./docker-compose.agent.yml down --remove-orphans
docker rm agent

create_agent_policy
get_enrollment_token
docker compose -f ./docker-compose.agent.yml up -d
docker logs -f agent