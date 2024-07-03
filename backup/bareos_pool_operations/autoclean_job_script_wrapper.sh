#!/usr/bin/env bash

# A wrapper for autoclean script because of new Bareos bug: you can't pass arguments like:
# --arg1 param1 --arg2 param2. See: https://bugs.bareos.org/view.php?id=1587
/./etc/bareos/bareos-dir.d/clean_expired_bareos_volumes.sh --action delete --expire 60 --name Full-
