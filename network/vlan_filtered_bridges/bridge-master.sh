#!/usr/bin/env bash


# Linux bridge set-up (for 'master-bridge').
# Copyright (c) 2018, Aleksandr Bazhenov

# Systemd unit and script to create bridge with VLAN filtering to prevent
# MAC-table overflow on the host. Actually bypass through the bridge VLAN
# range which was set. Here is a master and non-master bridges. Actually this
# is an example how to organize linux bridges by script.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential network connetcion loss and
# assumes you accept that you know what you're doing. All actions with this
# script at your own risk.


## Specify management network interfaces:
INTERFACE_CONTROL=ens3

## Specify bridge name:
IF_BRIDGE_NAME=brm

## Specify bridging interfaces:
IF_BRIDGING="(enp10|enp12)"


echo "Bridging ${IF_BRIDGING} to ${IF_BRIDGE_NAME} started at: $(date)"
INTERFACE_LIST=$(basename -a /sys/class/net/* | grep -iE $IF_BRIDGING | grep -v 'lo' | grep -v $INTERFACE_CONTROL)
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo brctl addbr $IF_BRIDGE_NAME

for INTERFACE_CURRENT in $INTERFACE_LIST
do
  echo "Up and bridging: $INTERFACE_CURRENT"
  sudo ifconfig "$INTERFACE_CURRENT" up
  sudo brctl addif $IF_BRIDGE_NAME "$INTERFACE_CURRENT"
done

sudo ifconfig $IF_BRIDGE_NAME up
echo 1 | sudo tee /sys/class/net/$IF_BRIDGE_NAME/bridge/vlan_filtering

for INTERFACE_CURRENT in $INTERFACE_LIST
do
  echo "Filtering on bridge vlan 4000-4094 for $INTERFACE_CURRENT"
  sudo bridge vlan add dev "$INTERFACE_CURRENT" vid 4000-4094
done

echo "Bridge stat:"
sudo brctl show $IF_BRIDGE_NAME
