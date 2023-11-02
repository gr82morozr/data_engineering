rm -fr ./certs
mkdir -p ./certs

docker compose down


chmod 440 ./apm-server.yml

cp  ../elk/elk.env ./.env


source ./.env
cp  ../elk/a/$ES_CLUSTER/config/certs/ca/ca.crt               ./certs/ca.crt
cp  ../elk/a/$ES_CLUSTER/config/certs/es-a1/es-a1.crt         ./certs/es-a1.crt
cp  ../elk/a/$ES_CLUSTER/config/certs/es-a1/es-a1.key         ./certs/es-a1.key
cp  ../elk/a/$ES_CLUSTER/config/certs/kibana/kibana.crt       ./certs/kibana.crt

docker compose build apm-svr
docker compose up -d


docker logs -f apm-svr


