# BTRFS re-balance script

A tiny script to perform btrfs re-balance with a range of `-dusage` values.

## Technical details

Running btrfs balance start without any filters, would rewrite every data and metadata chunk in the filesystem.
Usually, this is not what we want. Instead, use balance filters to limit what chunks should be balanced.

Using `-dusage=5` we limit balance to compact data blocks that are less than 5% full. This is a good start, and we can
increase it to 10–15% or more if needed. A small (less than 100GiB) filesystem may need a higher number. The goal here
is to make sure there is enough Unallocated space on each device in the filesystem to avoid the ENOSPC situation.

```bash
# btrfs balance start -dusage=5 /
Done, had to relocate 1 out of 68 chunks
```

([reference](https://wiki.tnonline.net/w/Btrfs/Balance))

If the percent starts from a small number, like 5 or 10, the chunks will be processed relatively quickly and will make
more space available. Increasing the percentage can then make more chunks compact by relocating the data.

Chunks utilized up to 50% can be relocated to other chunks while still freeing the space. With utilization higher than
50 %, the chunks will be basically only moved on the devices. The actual chunk layout may help to coalesce the free
space, but this is a secondary effect.

```bash
for USAGE in {10..50..10} do
    btrfs balance start -v -dusage=$USAGE mnt/
done
```

([reference](https://btrfs.readthedocs.io/en/latest/Balance.html))

Especially when you use docker, iterating over values can save space on "non-dense" data.

## Setting up crontab

Upload script as `/opt/scripts/btrfs_rebalance.sh`

```bash
useradd serviceuser
usermod -aG sudo serviceuser
echo "serviceuser ALL=(ALL) NOPASSWD: /bin/btrfs" >> /etc/sudoers
echo "10 5    * * *   serviceuser    bash /opt/scripts/btrfs_rebalance.sh" >> /etc/crontab
```
