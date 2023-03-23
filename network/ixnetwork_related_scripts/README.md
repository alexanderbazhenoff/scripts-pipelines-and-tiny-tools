traffic item stat and graph
===========================

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
