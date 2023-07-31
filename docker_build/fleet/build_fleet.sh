
echo "Getting Fleet service-token ... ";

source .env


until curl -k -u "elastic:${KIBANA_PASSWORD}" -s -X POST http://kibana:5601/api/fleet/service-tokens --header "kbn-xsrf: true" | grep -oP "\"value\":\"\\K[^\"]*"; do sleep 10; done;
curl -k -u "elastic:${KIBANA_PASSWORD}" -s -X POST http://kibana:5601/api/fleet/service-tokens --header "kbn-xsrf: true" | grep -oP "\"value\":\"\\K[^\"]*" > ./fleet.token
cat ./fleet.token

curl -u elastic:${KIBANA_PASSWORD}" --request POST \
  --url http://localhost:5601/api/fleet/agent_policies?sys_monitoring=true \
  --header 'content-type: application/json' \
  --header 'kbn-xsrf: true' \
  --data '{"name":"Agent policy 1","namespace":"default","monitoring_enabled":["logs","metrics"]}'

