#!/bin/sh
set -e
#--------------------------------------
# Start Envoy Proxy
#--------------------------------------
envoy --config-path /usr/local/envoy/config/envoy.yaml
