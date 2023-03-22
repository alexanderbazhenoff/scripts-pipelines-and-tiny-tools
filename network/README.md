## Network scripts

Configure and collect network settings on linux systems.

- [**get_dhcp_leases**](get_dhcpd_leases/README.md) - get leases info from isc-dhcp server including client, 
expiration and client vendor.
- [**inner_vps_bridge**](inner_vps_bridge/README.md) - example how to organize the network inside your VPS by
linux bridge.
- [**vlan_filtered_bridges**](vlan_filtered_bridges/README.md) - systemd unit and script to create bridge with
VLAN filtering to prevent MAC-table overflow on the host. Actually this is an example how to organize linux bridges by
script.
