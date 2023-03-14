#!/usr/bin/env bash


# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


## Specify management network interfaces:
ifacecontrol=ens3

## Specify bridge name:
ifbrigename=brm

## Specify bridging interfaces:
ifbridging="(enp10|enp12)"

echo "Bridging ${ifbridging} to ${ifbrigename} started at: $(date)"
ifacelist=$(basename -a /sys/class/net/* | grep -iE $ifbridging | grep -v 'lo' | grep -v $ifacecontrol)
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo brctl addbr $ifbrigename

for ifacecurrent in $ifacelist
do
  echo "Up and bridging: $ifacecurrent"
  sudo ifconfig "$ifacecurrent" up
  sudo brctl addif $ifbrigename "$ifacecurrent"
done

sudo ifconfig $ifbrigename up
echo 1 | sudo tee /sys/class/net/$ifbrigename/bridge/vlan_filtering

for ifacecurrent in $ifacelist
do
  echo "Filtering on bridge vlan 4000-4094 for $ifacecurrent"
  sudo bridge vlan add dev "$ifacecurrent" vid 4000-4094
done

echo "Bridge stat:"
sudo brctl show $ifbrigename
