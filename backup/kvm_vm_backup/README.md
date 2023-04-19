# BACKUP SCRIPT FOR KVM VIRTUAL MACHINES

*Running this script may cause potential data loss. Do on your own risk, otherwise you know what you're doing.*

This scripts allows you to perform backups of selected KVM virtual machines in various modes: active (live backup) or
stopped (every VM will be off before making a backup). Backing up of running machines based on 
[block commit](https://libvirt.org/kbase/internals/incremental-backup.html) libvirt technology.

## Usage
```bash
kvm_backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>
```

### Commands

Available the next commands (or scripts actions):

- `--active` - Create backup of running VM(s). Requierd: qemu-guest-agent installed on virtual machine and qemu-channel
  device created.
- `--stoped` - Stop, create backup and run virtual machine.
- `--clean` - Clean previous packups from backup folder.

### Examples

```bash
kvm_backup.sh --active vmname1 vmname2
kvm_backup.sh --stoped vmname3
kvm_backup.sh --clean vmname1 vmname2 vmname3
```

### Using with Bareos

It's possible to use this script to back up your KVM images with [Bareos](https://www.bareos.com/): use 'before' and
'after scripts'. The example bellows shows you how to back up virtual machine named 'my_machine' from 'my_server.domain'
in active mode then clean up on finish:

**/etc/bareos/bareos-dir.d/job/my_machine.conf**
```bash
Job {
  Name = "my_machine"
  Description = "Backup my_machine VM at my_server.domain"
  JobDefs = "my-jobdef"                 # read job defenition file /etc/bareos/bareos-dir.d/jobdefs/kvm-jobdef.conf
  Type = Backup
  Level = Full                           # using this script only full backup of VM is possible
  Accurate = yes
  FileSet = "my_backup_fileset"          # set-up your fileset
  Schedule = "my_schedule"               # set-up your schedule
  Client = "my_server.domain"            # your virtialization hostname with bareos file daemon installed
  ClientRunBeforeJob = "/var/lib/libvirt/images/kvm_backup.sh --active %n"     # where %n is the name of the job
  ClientRunAfterJob  = "/var/lib/libvirt/images/kvm_backup.sh --clean %n"      # or set VM name here 'my_machine'
  Write Bootstrap = "|/usr/bin/bsmtp -h localhost -f \"\(Bareos\) \" -s \"Bootstrap for Job %j\" root@localhost" # (#01)
  Priority = 10                          # set your priority
}  
```
**/etc/bareos/bareos-dir.d/jobdefs/my_jobdef.conf**
```bash
JobDefs {
  Name = "my_jobdef"
  Type = Backup
  Client = my_server.domain               # some of these params will be overwrite by job, but most of them should be 
  Schedule = "my_schedule"                # set here
  Storage = File
  Messages = Standard
  Pool = Full
  Priority = 10
  Write Bootstrap = "/var/lib/bareos/%c.bsr"
  Full Backup Pool = Full                  # write Full Backups into "Full" Pool         (#05)
}
```
**/etc/bareos/bareos-dir.d/fileset/kvm_vm_fileset.conf**
```bash
FileSet {
  Name = "kvm-vm-fileset"
  Include {
    Options {
      Compression = LZ4
      noatime = yes
      Verify = pin5
    }
   File = "/var/lib/libvirt/images/backup/"%n     # here is a path for your virtual machine backup with jobname %n
  }
}
```

## Requirements
- Backing up in `--active` mode required channel device (rg.qemu.guest_agent.0) and qemu-guest-agent to be installed on 
  the guest system. `apt install qemu-guest-agent` or `yum install qemu-guest-agent`. To check qemu-quest-agent 
  connection run the next command from the virtualization host:

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

- Please avoid the name included to another names of virtual machines in `--stoped` mode, e.g "test" and "test-24". 
  Otherwise, the time of creating backups will be increased on every include.
- There is no power-on detection in `--active` mode. Anyway the backup up of powered-off machine in `--active` mode will
  work and the machine boots up.

## License

[BSD 3-Clause License](../../LICENSE)

## URLs

1. https://wiki.libvirt.org/page/Qemu_guest_agent
2. https://access.redhat.com/solutions/732773
3. https://wiki.qemu.org/Features/GuestAgent
