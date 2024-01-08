#!/usr/bin/env bash


# An example how to organize the network inside your VPS by linux bridge:

# Usage:
# Create your loop device on VPS, e.g:
# $ cat /etc/network/interfaces
# The loopback network interface
# auto lo ens192
# iface lo inet loopback

# ----------------------------------------------------------------------------
# WARNING! Running this file may cause a potential network connetcion loss and
# assumes you accept that you know what you're doing. All actions with this
# script at your own risk.

# ----------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE


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
