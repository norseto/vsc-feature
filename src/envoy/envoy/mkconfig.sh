#!/bin/sh
set -e
#--------------------------------------
# Make Envoy Proxy Config
#--------------------------------------
gomplate -d cnf=/usr/local/envoy/config/proxy.yaml --input-dir /usr/local/envoy/config/templates --output-dir /tmp
mv /tmp/cds_template.yaml /usr/local/envoy/config/cds.yaml
mv /tmp/lds_template.yaml /usr/local/envoy/config/lds.yaml
