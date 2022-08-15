#!/bin/sh
set -e
#--------------------------------------
# Install Envoy Proxy
#--------------------------------------
NAME=envoy_$$
docker run -d --rm --name ${NAME} envoyproxy/envoy:v1.22.0 sleep 30
sleep 3
docker cp ${NAME}:/usr/local/bin/envoy /usr/local/bin/envoy
