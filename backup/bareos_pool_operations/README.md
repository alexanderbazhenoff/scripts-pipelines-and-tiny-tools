# Bareos scripts

**WARNING!** Running all these scripts may cause potential data loss. Do on your own risk; otherwise you know what
you're doing.

These scripts are for troubleshooting and a little help when you need to clean up, prune or prune Bareos pool after
unsuccessful or made by mistake task. Basically two scripts
([clean_expired_bareos_volumes.sh](clean_expired_bareos_volumes.sh) and
[batch_process_bareos_volumes.sh](batch_process_bareos_volumes.sh)) is more that enough, but here is some deprecated
scripts (see [Other Bareos troubleshooting examples](#other-bareos-troubleshooting-examples)) without a pass of arguments
from command-line.

Some scripts are only for file storage devices on SSF/HDD only (`Media Type = File`), e.g.:
[batch_process_bareos_volumes.sh](batch_process_bareos_volumes.sh),
[clean_expired_baros_volumes.sh](clean_expired_bareos_volumes.sh) or
[clean_missing_volumes.sh](clean_missing_volumes.sh) because of direct operations on files in storage pool. This has
never been tested on other types of pools (e.g. tapes).

## Common scripts

### clean_expired_bareos_volumes.sh

This script is useful if you need to delete a few volumes in the pool chosen by expiration date, pool name and(or)
volume status. Basically, this script is for autoclean of Bareos storage pool. But you can also gather expiration
volumes statistics, running with `--test yes` option.

**Requirements:**

- permissions to run `bconsole` command and access to **$poolpath** (don't mind if you run this script from Bareos Admin
  Job you're, otherwise you should edit `/etc/sudoers` or run from root).
- git package (`apt` or `yum install git` depending on your linux distro).

**Usage:**

- Example: `# ./clean_expired_baros_volumes.sh --name Full- --action delete --expire 10 --filter Pruned` will delete
  'Pruned' volumes selected by name mask 'Full-' ("Full" storage pool) after 10 days.
- Use `--test yes` key for test mode.
- Or run: `# ./clean_expired_baros_volumes.sh --help` for the help.

On large installations, it takes a long time to purge or shift data. Maybe you also want to delete force some volumes.
So you can use Admin Job with this script.

**Bareos Admin Job Example:**

```text
Job {
    Name = "Autoclean Pool"
    JobDefs = "DefaultJob"
    Schedule = "Daily"
    Type = "Admin"
    Priority = 1
    # 1 means to run immediately before other backup jobs

    RunScript {
        Runs When = Before
        Runs On Client = no
        # We don't need to run on the client until your storage daemon is not on the client
        Fail Job On Error = yes
        Command = "/etc/bareos/bareos-dir.d/clean_expired_bareos_volumes.sh --action delete --expire 60 --name Full-"
        # Place this script in bareos director configs repository and chmod +x
    }
}
```

For the latest versions (e.g., Bareos director 23.0.1) you can't pass script parameters directly, you should create
an additional bash script. Create `/etc/bareos/bareos-dir.d/my_wrapper_script.sh`:

```bash
#!/usr/bin/env bash

/etc/bareos/bareos-dir.d/clean_expired_bareos_volumes.sh --action delete --expire 60 --name Full-
```

and run them via a Bareos Admin job without parameters pass:

```text
       Command = "/etc/bareos/bareos-dir.d/my_wrapper_script.sh"
```

### batch_process_bareos_volumes.sh

Common-usage and the most multifunctional script for Bareos pool and volumes troubleshooting.

Apply action for a range of volumes:

```bash
./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force|print>
```

Action for the range of volumes in the pool with 'name_mask' (something like 'Incremental-' or 'Full-') to apply from
'start' to 'end' volume sequence. Action should be 'prune', 'purge' or 'delete'. Also, you need to set 'force' to
skip confirmation request or 'print' to get the info about the selected range of volumes. '--print' will not perform
changes in volume status, just output info.

## Other Bareos troubleshooting examples

Examples how to troubleshoot volume and pool problems in Bareos. Most versions of the scripts are for PostgreSQL and
MySQL Bareos installation (the last is for an old versions of Bareos, MySQL support dropped).

### clean_missing_volumes.sh

This script physically deletes non-existent volumes from Pool in the Bareos database. Just set up your `$POOLPATH`
inside the script and run.

### delete_all_volumes_from_pool_mysql.sh / delete_all_volumes_from_pool_pgsql.sh

Delete all volumes from the pool for an old MySQL Bareos installations, or newer PostgreSQL. Set your `$POOL_NAME`
inside the script and run.

### purge_all_volumes_from_pool_mysql.sh / purge_all_volumes_from_pool_pgsql.sh

Set all volumes in defined pool to "purged" state. Set your `$POOL_NAME` inside the script and run.

### prune_all_volumes_from_pool_mysql.sh / prune_all_volumes_from_pool_pgsql.sh

Same as the previous scripts, but sets to 'pruned' state.

### remove_purged_volumes.sh

Removes all volumes physically from the disk which are in 'purged' state.

## License

[BSD 3-Clause License](../../LICENSE)

## URLs

- [bareos.org](https://www.bareos.com/)
- [article on medium.com](https://medium.com/@alexander.bazhenov/bareos-%D0%B1%D0%B5%D1%81%D0%BF%D0%BB%D0%B0%D1%82%D0%BD%D0%BE%D0%B5-%D1%80%D0%B5%D0%B7%D0%B5%D1%80%D0%B2%D0%BD%D0%BE%D0%B5-%D0%BA%D0%BE%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D1%84%D0%BE%D1%80%D0%BC%D0%B0%D1%82%D0%B0-enterprise-d84b90a4415a)
- [docs.bareos.org](https://docs.bareos.org/)
