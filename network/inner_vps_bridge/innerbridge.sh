#!/usr/bin/env bash


# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


# Specify bridge name
BRIDGE_NAME="br0"
# Specify inner-network with CIDR
NETWORK="172.16.0.1/24"


echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
if ! sudo brctl show | grep -q ${BRIDGE_NAME}; then
	sudo brctl addbr $BRIDGE_NAME
	ip addr add $NETWORK dev $BRIDGE_NAME
	ip link set $BRIDGE_NAME up
fi
