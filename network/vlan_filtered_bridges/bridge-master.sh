#!/usr/bin/env bash


# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


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
