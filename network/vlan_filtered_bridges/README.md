vlan filtered bridges
=====================

Systemd unit and script to create bridge with VLAN filtering to prevent MAC-table overflow on the host. Actually bypass
through the bridge VLAN range which was set. Here is a master and non-master bridges. Actually this is an example how
to organize linux bridges by script.

- [`bridge.sh`](bridge.sh) - non-master bridge. Copy them to `/opt`.
- [`bridge-master.sh`](bridge-master.sh) - master bridge. Copy to `/opt`.
- [`cloud-bridge.service`](cloud-bridge.service) - systemd unit. Copy to `/etc/systemd/system/cloud-bridge.service`.
- [`README.md`](README.md) - this file.
