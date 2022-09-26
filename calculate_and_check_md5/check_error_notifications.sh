#!/usr/bin/env bash

MESSAGE=$1
HOSTNAME="$(hostname)"

# do something to send your error message
echo "$MESSAGE checking on $HOSTNAME failed."
