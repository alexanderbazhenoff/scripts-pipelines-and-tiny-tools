# Various pipelines

- [**get-dhcpd-leases**](get-dhcpd-leases/README.md) - Jenkins scripted pipeline. A tiny wrapper for
  [python script](https://github.com/alexanderbazhenoff/various-scripts/tree/master/network/get_dhcpd_leases) to get
  leases info from isc-dhcp-server.
- [**golang-app-docker-ci**](golang-app-docker-ci/README.md) - Jenkins scripted pipeline to clone golang sources of the 
  project, run tests inside docker container and archive docker image with application binary as artifacts.
- [**install-bareos**](install-bareos/README.md) - Jenkins scripted pipeline for installing and customizing Bareos 
  components, or a wrapper for
  [bareos](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos) ansible role.
- [**install-zabbix-agent**](install-zabbix-agent/README.md) - Jenkins scripted pipeline for installing and customizing 
  zabbix agent, or a wrapper for
  [zabbix_agent](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent) 
  ansible role.
