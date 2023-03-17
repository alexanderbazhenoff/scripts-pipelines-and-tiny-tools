get dhcp leases
===============

1. Download [oui.txt](https://standards-oui.ieee.org/) file to `/usr/local/etc/oui.txt` path on your isc-dhcp server.
2. Run on isc-dhcp (or dhcpd) server to get leases info: IP Address, MAC Address, Expires (days,H:M:S), Client Hostname
and Vendor (when possible).
