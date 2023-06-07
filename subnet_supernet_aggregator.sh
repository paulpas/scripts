#!/usr/bin/env bash

SUBNET=10.128.0.0
SUPERNET_CIDR=10
AGGREGATE_CIDR=19
ipcalc -n ${SUBNET}/${SUPERNET_CIDR} -s $(seq $(echo "2^(32-${SUPERNET_CIDR})/2^(32-${AGGREGATE_CIDR})" | bc)  | xargs -I{} echo -n "$(echo "2^(32-${AGGREGATE_CIDR})-2" | bc) ") | awk '/^Network:/ {print $2}'
