# Bareos scripts.

**WARNING!** Running all these script may cause potential data loss. Do on your own risk, otherwise you know what 
you're doing.

### clean_expired_baros_volumes.sh

This script is usefull if you need to delete a few volumes in the pool choosen by expiration date, pool name and(or)
volume status. Basically this script is for autoclean of Bareos storage pool. But you can also gather expiration volumes
statistics, running with `--test yes` option.

**Requirments:**

- permissions to run `bconsole` command and acess to **$poolpath** (don't mind if you run this script from bareos Admin 
  Job you're, otherwise you should edit `/etc/sudoers` or run from root).
- git pacakge (`apt` or `yum install git` depending on your linux distro).
- **shflags** library: https://code.google.com/archive/p/shflags/ This script automatically clone this to current
  directory.

**Usage:**

- Example: `# ./clean_expired_baros_volumes.sh --name Full- --action delete --expire 10 --filter Pruned` will delete
  'Pruned' volumes selected by name mask 'Full-' ("Full" storage pool) after 10 days.
- Use `--test yes` key for test mode.
- Or run: `# ./clean_expired_baros_volumes.sh --help` for the help.

On large installations it takes a long time to purge or shift data. May be you also want to force delete some volumes.
So you can use Admin Job with this script.

**Bareos Admin Job Example:**

```bash
Job {
    Name = "Autoclean Pool"
    JobDefs = "DefaultJob"
    Schedule = "Daily"
    Type = "Admin"
    Priority = 1
    # 1 means to run immediately before othe backup jobs

    RunScript {
        Runs When = Before
        Runs On Client = no
        # We don't need to run on the client until your storage daemon is not on the client
        Fail Job On Error = yes
        Command = "/etc/bareos/bareos-dir.d/clean_expired_baros_volumes.sh --action delete --expire 60 --name Full-"
        # Place this script in bareos director congigs repository and chmod +x
    }
}
```
# Other bareos troubleshooting examples:

Examples how to troubleshoot volume and pool problems in bareos.

### batch_process_bareos_volumes.sh
Apply action for a range of volumes:
```bash
./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force|print>
```
Action for the range of volumes in the pool with 'name_mask' (something like 'Incremental-' or 'Full-') to apply from
'start' to 'end' volume sequence. Action should be 'prune', 'purge' or 'delete'. Also you need to set 'force' to 
skip confirmation request or 'print' to get the info about selected range of volumes. '--print' will not perform changes
in volume status, just output an info.

### clean_missing_volumes.sh
This script physically delete non-existent volumes from Pool in the bareos database. Just set up your `$POOLPATH` inside
the script and run.

### delete_all_volumes_from_pool_mysql.sh / delete_all_volumes_from_pool_pgsql.sh
Delete all volumes from the pool for an old MySQL Bareos installations, or newner PostgreSQL. Set your `$POOL_NAME` 
inside the script and run.

### purge_all_volumes_from_pool_mysql.sh / purge_all_volumes_from_pool_pgsql.sh
Set all volumes in defined pool to "purged" state. Set your `$POOL_NAME` inside the script and run.

### prune_all_volumes_from_pool_mysql.sh / prune_all_volumes_from_pool_pgsql.sh
Same as the previous scripts, but sets to 'pruned' state.

### remove_purged_volumes.sh
Removes all voluems physically from the disk which are in 'purged' state.

## URLs:

- [bareos.org](https://www.bareos.com/)
- [my medium article](https://medium.com/@alexander.bazhenov/bareos-%D0%B1%D0%B5%D1%81%D0%BF%D0%BB%D0%B0%D1%82%D0%BD%D0%BE%D0%B5-%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%BD%D0%BE%D0%B5-%D0%BA%D0%BE%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D1%84%D0%BE%D1%80%D0%BC%D0%B0%D1%82%D0%B0-enterprise-d84b90a4415a)
- [docs.bareos.org](https://docs.bareos.org/)
