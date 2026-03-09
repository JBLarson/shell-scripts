#!/usr/bin/bash

# docker clean

docker image prune -a -f

docker ps -a | grep -E "api-|db-|dashboard-|pgadmin-" | grep -v "coolify" | awk '{print $1}' | xargs -r docker rm -f

docker system prune -f

