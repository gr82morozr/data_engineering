source ./.env

docker compose down --volumes --remove-orphans
#docker network prune -f
#docker volume prune -f


#docker rm -f $(docker ps -aq)
