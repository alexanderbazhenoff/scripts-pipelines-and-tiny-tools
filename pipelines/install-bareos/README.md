# Install Bareos Jenkins pipeline

A jenkins pipeline to install and configure Bareos and required third-party components, or a wrapper for
[bareos](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos)
ansible role. It gives you an opportunity do directly from Jenkins setting up pipeline parameters, without editing
ansible playbooks and running them from terminal.

## Requirements

1. Jenkins version 2.190.2 or higher.
2. [Linux jenkins node](https://www.jenkins.io/doc/book/installing/linux/) to run pipeline.
3. [AnsiColor Jenkins plugin](https://plugins.jenkins.io/ansicolor/) for colour console output.
4. [Ansible installation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on
   jenkins node(s). Required ansible version specified in
   [meta/main.yml](https://github.com/alexanderbazhenoff/ansible-collection-linux/blob/main/roles/bareos/meta/main.yml)
5. All other requirements from
   [zabbix_agent ansible role](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos#requirements).
6. This pipeline may require groovy methods approve. If you see a message like:
   'Scripts not permitted to use staticMethod ... Administrators can decide whether to approve or reject this signature'
   that means you need to allow them to execute. Navigate to `Jenkins -> Manage Jenkins -> In-process script
   approval`, find a blocked method (the newest one is usually at the bottom) then click 'Approve'. Or refactor this
   pipeline and move all these methods to
   [jenkins share library](https://www.jenkins.io/doc/book/pipeline/shared-libraries/).
7. Internet access on Jenkins node(s) to install alexanderbazhenoff.linux.zabbix_agent from GitHub (or put this to your
   local environment and change a URL in pipeline code).

## Usage

1. Create jenkins pipeline with 'Pipeline script from SCM', set-up SCM, Branch Specifier as `*/main` and Script Path as
   `install-bareos/install-bareos.groovy`.
2. Install [AnsiColor](https://plugins.jenkins.io/ansicolor/) jenkins plugin on jenkins master and restart jenkins.
3. Install ansible on your jenkins nodes, especially for user which jenkins pipelines runs (usually it's `jenkins`).
4. Specify defaults for jenkins pipeline parameters in a global variables of pipeline code:
    - **AnsibleInstallationName** is named path of your ansible installation from:
      `Jenkins -> Configure Jenkins -> Golbal Tool Configuration -> Ansible`, e.g:

      ```text
      Name: home_local_bin_ansible
      Path to ansible executables directory: $HOME/.local/bin/
      ```

      for your pip installation under user. Or check your installation path with `ansible --version` command.
      (Please take a notice global pipeline variables means a constants in a pipeline code, not in shared library or
      other global Jenkins settings.)
    - **NodesToExecute** is a list of jenkins nodes to execute on (with installed ansible), otherwise (if `[]`) this
      will run on jenkins master.
5. (optional) If you wish to connect Bareos server with ssh key instead of typing login and password in pipeline
   parameters, generate ssh keys and modify `~/.ssh/config` on your Jenkins nodes specified in **NodesToExecute**
   global pipeline variable. So login to jenkins user and generate key and add them to Bareos server:

   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_bareos
   ssh-copy-id -i ~/.ssh/id_rsa_bareos username@bareos.domain
   ```

   Set username in **BareosServerSshLogin** and bareos server in **BareosServerHost** global pipeline variables.
   Then add the next lines to your ssh config in home folder (e.g. `~/.ssh/config`). For example:

   ```text
    Host bareos bareos.domain
        hostname bareos.domnain
        port 22
        user username
        IdentityFile ~/.ssh/id_rsa_bareos
   ```

6. Optionally modify another jenkins pipeline global variables like: **ListOfBareosReleases**,
   **ListOfPostgreSqlVersions**, etc.
7. For security reasons you may wish to disable installation and/or control of various Bareos components. Check
   **ActionsEnabled** and **BareosComponentsEnabled** global pipeline variables for details. You can also enable or
   disable some Web UI user profiles creation in **WebUiProfilesEnabled** and/or allow or disallow Bareos configs
   copy for various actions in **BareosCopyConfigsParams** global jenkins variables.
8. If you have fork an ansible project with Bareos role to your local repository you can specify a repository URL in
   **AnsibleGitRepoUrl** and credentials to access in **GitCredentialsId** global pipeline variables.
9. Run pipeline twice. The first run injects jenkins pipeline parameters with your defaults which was specified on
   step 2.
10. Optionally you can set permissions who can run this pipeline (see 'Enable project-based security' in the Jenkins
    pipeline settings).

## Pipeline parameters

### Main Bareos parameters

- **IP_LIST**: Space separated IP or DNS list for install/uninstall components and copy configs.
- **SSH_LOGIN**: Login for SSH connection for install/uninstall components and copy configs (The same for all hosts).
- **SSH_PASSWORD**: SSH password for install/uninstall components and copy configs (The same for all hosts).
- **SSH_SUDO_PASSWORD**:SSH sudo password or root password for install/uninstall components and copy configs (The same
  for all hosts). If this parameter is empty SSH_PASSWORD will be used.
- **ACTION**: Action to perform:
  - **install_and_add_client**: install and add file daemon;
  - **access**: create user profile to access Bareos Web UI;
  - **revoke_access**: revoke user profile access to Bareos Web UI;
  - **add_client**: add already installed Bareos file daemon to director;
  - **copy_configs**: git clone and copy configs to already installed components;
  - **install**: install Bareos components;
  - **uninstall**: uninstall Bareos components.
- **BAREOS_COMPONENTS**: Bareos components to install or uninstall: **fd** - file daemon, **sd** - storage daemon,
  **dir** - director, **webui** - Web UI, **dir_webui** - director and Web UI.
- **BAREOS_RELEASE**: Bareos version.
- **OVERRIDE_LINUX_DISTRO_VERSION**: Override ansible linux distribution major version. Useful when specified Bareos
version repository is not available for your Linux distribution version (example: Bareos v21 currently is
[not available](https://download.bareos.org/bareos/release/21/) for any RedHat v9, so try to set `8` here).

### Bareos file daemon and Bareos server parameters

- **FILE_DAEMON_NAME**: Name of file daemon to display on Bareos server on file daemon add (leave '' for FQDN or
  hostname).
- **FILE_DAEMON_PASSWORD**: Password to connect file daemon with (leave unspecified to generate random password).
- **USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS**: Use pipleine constants for Bareos Server SSH access for file
  daemon add and Web UI access control, otherwise set BAREOS_SERVER, BAREOS_SERVER_SSH_LOGIN and
  BAREOS_SERVER_SSH_PASSWORD (login and become are the same).
- **BAREOS_SERVER**: Bareos server IP address or DNS for file daemon add, grant/revoke Web UI access.
- **USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER**: Use prepared on jenkins node ssh keys and config to connect Bareos server,
  otherwise uncheck and set login and password.
- **BAREOS_SERVER_SSH_LOGIN**: Bareos Server SSH login for Bareos client add, grant/revoke Web UI access.
- **BAREOS_SERVER_SSH_PASSWORD**: Bareos Server SSH password for Bareos client add, grant/revoke Web UI access.

### Bareos Web UI parameters

- **WEBUI_USERNAME**: Web UI username to create or revoke access.
- **WEBUI_PASSWORD**: Web UI password to create or revoke access.
- **WEBUI_PROFILE**: Web UI access profile.
- **WEBUI_TLS_ENABLE**: Use TLS (certificate creation not supported by this pipeline and
[bareos role](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos).

### Bareos database parameters

- **PREINSTALLED_POSTGRESQL**: Already preinstalled PostgreSQL before Bareos director install.
- **POSTGRESQL_VERSION**: Version of PostgreSQL to install.
- **INIT_BAREOS_DATABASE**: Force init Bareos database (run scripts) before Bareos install (for CentOS 7 will run
  anyway).

### Other Bareos parameters

- **INSTALL_ADDITIONAL_BAREOS_PACKAGES**: Space separated list of additional Bareos packages to install.
- **CONFIGS_GIT_URL**: Bareos configs git URL (e.g. for **copy_configs** action).
- **CONFIGS_GIT_BRANCH**: Bareos configs git branch. Leave empty to skip configs copy.

### Pipeline main parameters

- **ANSIBLE_GIT_BRANCH**: Git branch of ansible project with bareos role.
- **DEBUG_MODE**: Verbose output.
- **JENKINS_NODE**: Jenkins node to execute this pipeline and ansible role.

For more information read ansible role
[description](https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos).

Please keep in mind if you enable or disable some pipeline actions and/or Bareos components you should update
pipeline parameters (some of them re-created, some of them not). Remove any sing pipeline parameter (see 'This
project is parametrised' option in pipeline settings) and run pipeline again.
