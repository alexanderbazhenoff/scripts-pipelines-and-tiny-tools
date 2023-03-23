IxNetwork related scripts
=========================

A set of various scripts to maintain, automate and interact with 
[IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916).


### clean_ixnetwork_logs_and_stats.bat

A script to place on [IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916) to perform logs, stats and
error dumps clean-up to decrease disk space usage. No parameters required, just edit days expire days for files 
clean-up inside the [bat](clean_ixnetwork_logs_and_stats.bat) script. Then create a new task in a Task scheduler with
'Run whether user is logged on or not' and 'Run with the highest privileges' options.


### traffic_item_statistics.py

Script that build traffic item statistics on the graph from 
[IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916) CSV results file.

#### Usage:

1. Install [plotly](https://plotly.com/python/) and [pandas](https://pandas.pydata.org/) on your system:
`pip install plotly pandas`.
2. Run:
```bash
python $PWD/graph/traffic_item_statistics.py -i $PWD/stats_example/csv/Traffic\ Item\ Statistics.csv \
  -o $PWD/stats_example/ -t 'test_name' -m 'Traffic Item 1'
```
to build graph from [`stats_example/Traffic Item Statistics.csv`](stats_example/Traffic Item Statistics.csv) and 
save them to html file.
