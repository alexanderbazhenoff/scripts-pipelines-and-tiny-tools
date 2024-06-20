# Install zabbix agent Jenkins pipeline

A jenkins pipeline for installing and customizing zabbix agent, or a wrapper for
[zabbix_agent](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent)
ansible role. It gives you an opportunity do directly from Jenkins setting up pipeline parameters, without editing
ansible playbooks and running them from terminal.

## Requirements

1. Jenkins version 2.190.2 or higher.
2. [Linux jenkins node](https://www.jenkins.io/doc/book/installing/linux/) to run pipeline.
3. [AnsiColor Jenkins plugin](https://plugins.jenkins.io/ansicolor/) for colour console output.
4. [Ansible installation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on
   jenkins node(s). Required ansible version specified in
   [meta/main.yml](https://github.com/alexanderbazhenoff/ansible-collection-linux/blob/main/roles/zabbix_agent/meta/main.yml)
5. All other requirements from
[zabbix_agent ansible role](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent#requirements).
6. This pipeline may require groovy methods approve. If you see a message like:
   'Scripts not permitted to use staticMethod ... Administrators can decide whether to approve or reject this signature'
   that means you need to allow them to execute. Navigate to `Jenkins -> Manage Jenkins -> In-process script
   approval`, find a blocked method (the newest one is usually at the bottom) then click 'Approve'. Or refactor this
   pipeline and move all these methods to
   [jenkins share library](https://www.jenkins.io/doc/book/pipeline/shared-libraries/).
7. Internet access on Jenkins node(s) to install alexanderbazhenoff.linux.zabbix_agent from GitHub (or put this to your
   local environment and change the URL in pipeline code).

## Usage

1. Create jenkins pipeline with 'Pipeline script from SCM', set-up SCM, Branch Specifier as `*/main` and Script Path as
   `install-zabbix-agent/install-zabbix-agent.groovy`.
2. Specify defaults for jenkins pipeline parameters in a global variables of pipeline code:
   - **AnsibleInstallationName** is named path of your ansible installation from:
     `Jenkins -> Configure Jenkins -> Golbal Tool Configuration -> Ansible`, e.g:

     ```text
     Name: home_local_bin_ansible
     Path to ansible executables directory: $HOME/.local/bin/
     ```

     for your pip installation under user. Or check your installation path with `ansible --version` command.
   - **NodesToExecute** is a list of jenkins nodes to execute on (with installed ansible), otherwise this will run
     on jenkins master.
   - **ZabbixAgentVersions** is a list of zabbix agent versions.
   Other variables you can also set from a jenkins GUI on the second pipeline run.
3. Install [AnsiColor](https://plugins.jenkins.io/ansicolor/) jenkins plugin on jenkins master and restart jenkins.
4. Run pipeline twice. The first run injects jenkins pipeline parameters with your defaults which was specified on
   step 2.

## Pipeline parameters

- **IP_LIST**: Space separated IP or DNS list.
- **SSH_LOGIN**: Login for SSH connection (The same for all hosts).
- **SSH_PASSWORD**: SSH password (The same for all hosts).
- **SSH_SUDO_PASSWORD**: SSH sudo password or root password (The same for all hosts). If this parameter is empty
  SSH_PASSWORD will be used.
- **INSTALL_AGENT_V2**: Install
  [Zabbix agent v2](https://www.zabbix.com/documentation/current/en/manual/concepts/agent2) when possible.
- **CUSTOMIZE_AGENT**: Configure Zabbix agent config for service discovery.
- **CUSTOMIZE_AGENT_ONLY**: Configure Zabbix agent config for service discovery without install.
- **ZABBIX_AGENT_VERSION**: List of [zabbix agent versions](https://www.zabbix.com/download_agents) to select.
- **CLEAN_INSTALL**: Remove old versions of Zabbix agent with configs first.
- **CUSTOM_PASSIVE_SERVERS_IPS**: Custom Zabbix Servers Passive IP(s). Split this by comma for several IPs. Leave this
  field blank for default Zabbix Servers IPs.
- **CUSTOM_ACTIVE_SERVERS_IPS**: Custom Zabbix Servers Active IP(s) and port(s), e.g.: A.B.C.D:port. Split this by comma
  for several IPs. Leave this field blank for default IPs.
- **ANSIBLE_GIT_URL**: GitHub or Gitlab URL of ansible project with install_zabbix role to git clone
  (e.g. `https://github.com/alexanderbazhenoff/ansible-collection-linux.git`).
- **ANSIBLE_GIT_BRANCH**: GitHub or Gitlab URL of branch of ansible project with install_zabbix role.
- **JENKINS_NODE**: List of possible jenkins nodes to execute.
- **DEBUG_MODE**: Verbose output of ansible playbooks execution.

For more information read ansible role
[description](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent).
