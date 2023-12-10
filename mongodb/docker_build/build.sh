export NETWORK_NAME=data-network

docker compose down

# created shared networks
if [ "$(docker network ls | grep $NETWORK_NAME)" ]; then
  echo "The network $NETWORK_NAME already exists."
else
  docker network create --driver bridge $NETWORK_NAME
  echo "The network $NETWORK_NAME created."
fi


docker compose up -d



