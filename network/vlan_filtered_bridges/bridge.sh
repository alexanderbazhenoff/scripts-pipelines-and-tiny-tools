#!/usr/bin/env bash


# Linux bridge set-up.

# Systemd unit and script to create bridge with VLAN filtering to prevent
# MAC-table overflow on the host. Actually bypass through the bridge VLAN
# range which was set. Here is a master and non-master bridges. Actually this
# is an example how to organize linux bridges by script.

# Copyright (c) 2018, Aleksandr Bazhenov

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential network connetcion loss and
# assumes you accept that you know what you're doing. All actions with this
# script at your own risk.


## Specify management network interfaces:
INTERFACE_CONTROL=ens3

## Specify bridge name:
IF_BRIDGE_NAME=br0

## Specify bridging interfaces:
IF_BRIDGING="(enp6|enp8)"


echo "Bridging ${IF_BRIDGING} to ${IF_BRIDGE_NAME} started at: $(date)"
INTERFACE_LIST=$(basename -a /sys/class/net/* | grep -iE $IF_BRIDGING | grep -v 'lo' | grep -v $INTERFACE_CONTROL)
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo brctl addbr $IF_BRIDGE_NAME
sudo ifconfig $IF_BRIDGE_NAME up
sudo ifconfig $IF_BRIDGE_NAME mtu 9200

for INTERFACE_CURRENT in $INTERFACE_LIST
  do
    echo "Up and bridging: $INTERFACE_CURRENT"
    sudo ifconfig "$INTERFACE_CURRENT" up
    sudo brctl addif $IF_BRIDGE_NAME "$INTERFACE_CURRENT"
    sudo ifconfig "$INTERFACE_CURRENT" mtu 9200
  done

echo 1 | sudo tee /sys/class/net/$IF_BRIDGE_NAME/bridge/vlan_filtering

for INTERFACE_CURRENT in $INTERFACE_LIST
  do
    echo "Filtering on bridge vlan 498-4094 for $INTERFACE_CURRENT"
    sudo bridge vlan add dev "$INTERFACE_CURRENT" vid 498-4094
  done

echo "Bridge stat:"
sudo brctl show $IF_BRIDGE_NAME
echo "MTU size(s):"
netstat -i | awk '{print $1,$2}'
