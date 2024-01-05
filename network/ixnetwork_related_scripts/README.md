# IxNetwork related scripts

A set of various scripts to maintain, automate and interact with
[IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916).


## [clean_ixnetwork_logs_and_stats.bat](clean_ixnetwork_logs_and_stats.bat)

A script to place on [IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916) to perform logs, stats and
error dumps clean-up to decrease disk space usage. No parameters required, just edit days expire days for files 
clean-up inside the [bat](clean_ixnetwork_logs_and_stats.bat) script. Then create a new task in a Task scheduler with
'Run whether user is logged on or not' and 'Run with the highest privileges' options.


## [ixnetwork_server_at_7999_10999_default_user.bat](ixnetwork_server_at_7999_10999_default_user.bat)

Example how to run IxNetwork server from command-line on specified port(s). You can add them to **winlogon** for example
and/or on
[RDP user login](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/set-up-logon-script-terminal-server-users).


## [ixnetwork_server_at_7999_10999.bat](ixnetwork_server_at_7999_10999.bat)

The same as [ixnetwork_server_at_7999_10999_default_user.bat](ixnetwork_server_at_7999_10999_default_user.bat), but for
specific user (`jenkins` in this case). Actually, this is workaround of IxNetwork server autostart which can't be run 
without a user login. Connect via RDP by specific user (`jenkins`) to run IxNetwork server, e.g.:
```bash
sudo xfreerdp /v:ixnetwork-server.domain /u:jenkins /p:your_password /cert-ignore &
```


## [ixnetwork_server_rdp_start_jenkins_pipeline.groovy](ixnetwork_server_rdp_start_jenkins_pipeline.groovy)

A scripted jenkins pipeline which you can optionally add to run IxNetwork via RDP connection by schedule:

1. Add this pipeline code by copy/paste to your jenkins pipeline or create them from gitSCM.
2. Edit pipeline variables to set your RDP login creation:

   - **IxNetworkRdpHost** (e.g. `'ixnetwork.domain'`) - RDP host to connect.
   - **IxNetworkRdpPass** (e.g. `'some_password'` - RDP password. The same for all users.
   - **UserList** (e.g. `['jenkins', 'jenkins2']`) - a list of RDP users to iterate on RDP connection.
3. Run this pipeline.


## [traffic_item_statistics.py](traffic_item_statistics.py)

Script that build traffic item statistics on the graph from 
[IxNetwork server](https://support.ixiacom.com/version/ixnetwork-916) CSV results file.

## Usage

1. Install [plotly](https://plotly.com/python/) and [pandas](https://pandas.pydata.org/) on your system:
`pip install plotly pandas`.
2. Run:

```bash
python $PWD/graph/traffic_item_statistics.py -i $PWD/stats_example/csv/Traffic\ Item\ Statistics.csv \
  -o $PWD/stats_example/ -t 'test_name' -m 'Traffic Item 1'
```

to build graph from [`stats_example/Traffic Item Statistics.csv`](stats_example/Traffic Item Statistics.csv) and
save them to HTML file.
