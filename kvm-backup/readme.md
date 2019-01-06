# BACKUP SCRIPT FOR KVM VIRTUAL MACHINES ##############
This scripts allows you to perform backups of selected KVM virtual machines in various modes: active (live backup) or stoped (every VM will be off before making a backup).

## Usage:
```bash
kvm-backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>
```
**Commands:**
- `--active` - Create backup of running VM(s). Requierd: qemu-guest-agent installed on virtual machine and qemu-channel device created.
- `--stoped` - Stop, create backup and run virtual machine.
- `--clean` - Clean previous packups from backup folder.

**Examples:**

```bash
kvm-backup.sh --active vmname1 vmname2
kvm-backup.sh --stoped vmname3
kvm-backup.sh --clean vmname1 vmname2 vmname3
```

## Requirments and specs:
- `--active` mode required channel device (rg.qemu.guest_agent.0) and qemu-guest-agent to be installed on the guest system. `apt install qemu-guest-agent` or `yum install qemu-guest-agent`. If you with to check qemu-quest-agent connection run this command from the host:

```bash
virsh qemu-agent-command <virtual-machine-name> '{"execute":"guest-info"}'
```

If still there's no connection try to add:
```xml
<source mode='bind' path='/var/lib/libvirt/qemu/f16x86_64.agent'/>
```

to your channel device section of VM config, e.g.:

```xml
<channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <source mode='bind' path='/var/lib/libvirt/qemu/f16x86_64.agent'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>
```

More information:
1. https://wiki.libvirt.org/page/Qemu_guest_agent
2. https://access.redhat.com/solutions/732773
3. https://wiki.qemu.org/Features/GuestAgent

- Please avoid the name which included to another names of virtual machines in `--stoped` mode, e.g "test" and "test-24". Otherwise the time of creating backups will increased by five minutes on every include. So if you run this script for "test", "test-24" and "test-24-2" backup time will be increased by 10 minutes.
- There is no power-on detection in `--active` mode. Do not be afraid of some strange messages without path or empty lines, if your virtual machines are suddenly off. Anyway your backups will be created.
