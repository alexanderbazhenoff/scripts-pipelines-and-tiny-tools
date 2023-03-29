get dhcpd leases
================

To get leases info from isc-dhcp-server (dhcpd):

1. Download [oui.txt](https://standards-oui.ieee.org/) file to `/usr/local/etc/oui.txt` path on your isc-dhcp server. Or
download this file to your custom path then change `VENDORS_FILE_PATH` variable in the script.
2. Run [get_dhcp_leases.py](get_dhcpd_leases.py) script on isc-dhcp (or dhcpd) server to get leases info: IP Address,
MAC Address, Expires (days,H:M:S), Client Hostname and Vendor (when possible).
