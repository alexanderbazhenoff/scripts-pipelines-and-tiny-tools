<!-- markdownlint-disable MD033 MD041 -->

<!-- docs-ci-cut-begin -->
<div align='center'>

# Scripts, pipelines, and tiny tools

A set of system administration, Linux/Unix engineering scripts, CI pipelines, and tiny tools.
<!-- markdown-link-check-disable -->
[![MegaLinter](https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/actions/workflows/mega-linter.yml/badge.svg?branch=master)](https://megalinter.io/)
[![GitHub License](https://img.shields.io/github/license/alexanderbazhenoff/scripts-pipelines-and-tiny-tools)](LICENSE)
<!-- markdown-link-check-enable -->
</div>

## API

API-related script to interact.

- [**send_message_via_telegram_bot**](api/send_message_via_telegram_bot/README.md) - script to send a message via bot in
  Telegram messenger.

## Backup scripts

An infrastructure-ready scripts for backup, restore and maintenance your data.

- [**backup_btrfs_filesystem_using_snapshots**](backup/backup_btrfs_using_snapshot/README.md) - example how to backups
  btrfs filesystems using snapshots.
- [**backup_lxc_and_filesystem_path**](backup/backup_lxc_and_filesystem_path/README.md) - backup, encrypt, and restore a
  filesystem path to remote drives with UID/GUI storing (especially for containers) on Linux systems.
- [**bareos_pool_operations**](backup/bareos_pool_operations/README.md) - batch process to remove and clean-up
  [Bareos](https://www.bareos.com/) volumes in the pool.
- [**calculate_and_check_md5**](backup/calculate_and_check_md5) - calculate and check md5 of required folder.
- [**gitlab_dump_and_restore**](backup/gitlab_dump_and_restore/README.md) - create GitLab dump and restore gitlab from a
  dump.
- [**kvm_vm_backup**](backup/kvm_vm_backup/README.md) - backup running or stopped
[Kernel Virtual Machine (KVM)](https://www.linux-kvm.org/page/Main_Page) instance(s) on Linux systems.
- [**mysql_dump**](backup/mysql_dump/README.md) - bash and batch command file examples of MySQL dump.

## Benchmark scripts

A set of scripts to benchmarks and performance stats.

- [**filesystems_benchmarks**](benchmark/filesystems_benchmarks/README.md) - a set of filesystem benchmark and
  performance comparison scripts.

## CLI

CLI-related scripts.

- [**btrfs re-balance**](cli/btrfs_rebalance/README.md) - a tiny script to perform btrfs re-balance with a range of
  `-dusage` values.

## Network scripts

Configure and collect network settings and software on operating systems.

- [**get_dhcp_leases**](network/get_dhcpd_leases/README.md) - a script and Jenkins pipeline-wrapper to get leases info
  from isc-dhcp server including client, expiration, and client vendor.
- [**inner_vps_bridge**](network/inner_vps_bridge/README.md) - example how to organize the network inside your VPS by
  linux bridge.
- [**ixnetwork_related_scripts**](network/ixnetwork_related_scripts/README.md) -
  [IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916) related scripts: automation, interaction, etc.
- [**openvpn_portscan**](network/openvpn_portscan/README.md) - scan to find possible openvpn port(s) on remote hosts.
- [**vlan_filtered_bridges**](network/vlan_filtered_bridges/README.md) - systemd unit and script to create bridge with
  VLAN filtering to prevent MAC-table overflow on the host. Actually this is an example how to organize linux bridges by
  script.

## Pipelines

A set of CI-CD pipelines.

- [**golang-app-docker-ci**](pipelines/golang-app-docker-ci/README.md) - Jenkins pipeline (scripted style) to clone golang
  sources of the project, run tests inside docker container and archive docker image with application binary as
  artifacts.
- [**install-bareos**](pipelines/install-bareos/README.md) - Jenkins pipeline (scripted style) for installing and customizing
  Bareos components, or a wrapper for
  [bareos](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos) ansible role.
- [**install-zabbix-agent**](pipelines/install-zabbix-agent/README.md) - Jenkins pipeline (scripted style) for installing and
  customizing zabbix agent, or a wrapper for
  [zabbix_agent](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent)
  ansible role.
