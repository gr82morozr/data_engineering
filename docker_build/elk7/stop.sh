#!/bin/bash

source ./.env
#docker compose down -v --rmi all
docker compose down --volumes --remove-orphans
