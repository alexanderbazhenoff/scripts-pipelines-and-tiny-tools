# get dhcpd leases

Script and Jenkins pipeline to get leases info from isc-dhcp-server (dhcpd).

## Requirements

1. dhcpd server installed on `ExecutionNode` node.
2. Jenkins server version 2.190.2 or higher (older versions are probably also fine, but wasn't tested).
3. [Linux jenkins node](https://www.jenkins.io/doc/book/installing/linux/) installed and configured on your dhcp
   server to run this pipeline.
4. python3 installed both on `StartNode` and `ExecutionNode`.
5. Download [oui.txt](https://standards-oui.ieee.org/) file to `/usr/local/etc/oui.txt` path on your isc-dhcp server. Or
   download this file to your custom path then change `VENDORS_FILE_PATH` variable in the script.

## Script usage

1. Download [oui.txt](https://standards-oui.ieee.org/) file to `/usr/local/etc/oui.txt` path on your isc-dhcp server. Or
download this file to your custom path then change `VENDORS_FILE_PATH` variable in the script.
2. Run [get_dhcp_leases.py](get_dhcpd_leases.py) script on isc-dhcp (or dhcpd) server to get leases info: IP Address,
MAC Address, Expires (days,H:M:S), Client Hostname and Vendor (when possible).

## Pipeline usage

1. Create jenkins pipeline with 'Pipeline script from SCM', set-up SCM, Branch Specifier as `*/main` and Script Path as
   `get-dhcpd-leases/get-dhcpd-leases.groovy`.
2. Specify defaults for jenkins pipeline parameters in a global variables of pipeline code.
