docker stop $(docker ps -aq)
docker system prune -f
docker system prune -a -f
