#!/usr/bin/env groovy


/**
 * Install Bareos.
 *
 * A jenkins pipeline wrapper for Bareos installation and configuring.
 * alexanderbazhenoff.linux.bareos ansible role:
 * https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/bareos
 * https://galaxy.ansible.com/alexanderbazhenoff/linux
 *
 * Requires:
 * - AnsiColor Jenkins plugin: https://plugins.jenkins.io/ansicolor/
 * - Ansible Jenkins plugin: https://plugins.jenkins.io/ansible/
 *
 * This Source Code Form is subject to the terms of the BSD 3-Clause License.
 * If a copy of the source distributed without this file, you can obtain one at:
 * https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE
 */


import groovy.text.StreamingTemplateEngine
import org.codehaus.groovy.runtime.StackTraceUtils


/**
 *  Pipeline constants to enable or disable features.
 */
// Due to security reasons you can enable or disable various actions, Bareos components and/or copy config(s) params:
final Map ActionsEnabled =
        [install_and_add_client: [state      : true,
                                  description: 'install and add file daemon'],
         access                : [state      : true,
                                  description: 'create user profile to access Bareos Web UI'],
         revoke_access         : [state      : true,
                                  description: 'revoke user profile access to Bareos Web UI'],
         add_client            : [state      : true,
                                  description: 'add already installed Bareos file daemon to director'],
         copy_configs          : [state      : true,
                                  description:
                                          'git clone and copy configs to already installed components'],
         install               : [state      : true,
                                  description: 'install Bareos components'],
         uninstall             : [state      : true,
                                  description: 'uninstall Bareos components']]
final Map BareosComponentsEnabled = [fd       : [state: true, description: 'file daemon'],
                                     sd       : [state: true, description: 'storage daemon'],
                                     dir      : [state: true, description: 'director'],
                                     webui    : [state: true, description: 'Web UI'],
                                     dir_webui: [state: true, description: 'director and Web UI']]
/* groovylint-disable DuplicateMapLiteral, DuplicateStringLiteral */
final Map WebUiProfilesEnabled = ['webui-admin'   : [state: true],
                                  operator        : [state: true],
                                  'webui-limited' : [state: true],
                                  'webui-readonly': [state: true]]
final Map BareosCopyConfigsParams = [
        fd          : [:],
        sd          : [:],
        dir         : [source: '/configs', destination: '/etc', owner: 'bareos', group: 'bareos'],
        webui       : [:],
        dir_webui   : [source: '/configs', destination: '/etc', owner: 'bareos', group: 'bareos'],
        copy_configs: [source: '/configs', destination: '/etc', owner: 'bareos', group: 'bareos']
]
/* groovylint-enable DuplicateMapLiteral, DuplicateStringLiteral */

// Git credentials ID to clone ansible (e.g. a222b01a-230b-1234-1a12345678b9):
final String GitCredentialsId = ''

/**
 *  Default pipeline parameters
 */
// List of Bareos versions selection for pipeline parameters injection (first run):
final List ListOfBareosReleases = ['current', 'next']

// List of PostgreSQL versions selection for pipeline parameters injection (first run):
final List ListOfPostgreSqlVersions = [14, 15]

// List of additional Bareos packages to install for pipeline parameters injection (first run):
final String InstallAdditionalBareosPackagesDefaults = 'bareos-traymonitor'

// Default ansible project git branch for pipeline parameters injection (first run):
final String DefaultAsnibleGitBranch = 'main'

// Default Bareos configs git URL for pipeline parameters injection (first run):
final String DefaultBareosConfigsUrl = ''

// Default Bareos configs git branch for pipeline parameters injection (first run). Typically this is main/master, but
// empty by default to prevent copying on file daemon install:
final String DefaultBareosConfigsBranch = ''

// Folder inside of bareos configs git project to copy from:
final String BareosConfigsSouthRelativePath = '/bareos'

// ssh private key filename to access Bareos server, which should be uploaded to $HOME/.ssh and added to Bareos server:
final String SshPrivateKeyFilename = 'id_rsa_bareos'

// Bareos server IP or DNS when USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS set:
final String BareosServerHost = 'bareos.domain'

// Bareos server ssh user when USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS set:
final String BareosServerSshLogin = 'username'

// Bareos ssh password when USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS and USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER
// was set. Actually it's almost useless, because of using ssh key is easier:
final String BareosServerSshPassword = ''

/**
 *  Other pipeline parameters, playbook template parts, inventory files, ansible repo path, etc.
 */
// Set Git URL, or leave them empty to install collection(s) defined in AnsibleCollectionsNames from ansible galaxy:
final String AnsibleGitRepoUrl = 'https://github.com/alexanderbazhenoff/ansible-collection-linux.git'
final String AnsibleCollectionName = 'alexanderbazhenoff.linux'

// Force install ansible galaxy every single pipeline run, otherwise will not install newer version. In most cases
// it's true. See this thread: https://github.com/ansible/ansible/issues/65699
// So if you wish to freeze an old version, e.g. if a lot of changes in new version of ansible collection.
final Boolean ForceInstallAnsibleCollection = true

// List of nodes to execute ansible:
final List NodesToExecute = ['node-name.domain']

// Ansible playbook template to execute on pipeline run. Variables inside will be templated from pipeline params.
final String AnsibleDefaultPlaybookTemplate = '''\
---

- hosts: all
  become: True
  become_method: sudo

  vars:
    additional_bareos_packages: '$INSTALL_ADDITIONAL_BAREOS_PACKAGES'
    configs_to_copy: $bareos_configs_to_copy

  tasks:
    - name: "install bareos pipeline | Include Bareos role to perform required action: $ACTION"
      ansible.builtin.include_role:
        name: $ansible_collection.bareos
      vars:
        role_action: $ACTION
        bareos_components: $BAREOS_COMPONENTS
        bareos_release: $BAREOS_RELEASE
        override_ansible_distribution_major_version: $OVERRIDE_LINUX_DISTRO_VERSION
        $add_component_name_parameter_line
        $add_component_password_parameter_line
        add_component_server: $add_component_server
        init_bareos_database: "{{ (ansible_distribution == 'CentOS' or $INIT_BAREOS_DATABASE) }}"
        postgresql_version: $POSTGRESQL_VERSION
        webui_username: $WEBUI_USERNAME
        webui_password: $WEBUI_PASSWORD
        webui_profile: $WEBUI_PROFILE
        webui_tls_enable: $WEBUI_TLS_ENABLE
        install_additional_bareos_packages: "{{ additional_bareos_packages.split(' ') | list }}"
        bareos_configs_to_copy: "{{ configs_to_copy | default([]) }}"
        debug_mode: $DEBUG_MODE
      when: $ansible_hosts_condition
'''

/** Ansible inventory templates and it's parts with different connection options. */
final String AnsibleInventoryTemplate = '''\
[$ansible_hosts_group]
$ansible_group_hosts

[$ansible_hosts_group:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
# ansible connection $ansible_hosts_group options
'''

final String AnsibleInventoryPasswordConnectionOptions = '''\
ansible_become_user=root
ansible_ssh_user=$ansible_user
ansible_ssh_pass=$ansible_password
ansible_become_pass=$ansible_become_password
'''

final String AnsibleInventorySshKeyConnectionOptions = '''\
ansible_user=$ansible_user
ansible_ssh_private_key_file=$home_folder/.ssh/$private_ssh_key_file_name
'''


/**
 * Make list of enabled options from status map.
 *
 * @param optionsMap - Map with item status and description, e.g:
 *                     [option_1: [state: true, description: 'text_1'],
 *                     option_2: [state: false, description: 'text_2']]
 * @param formatTemplate - String format template, e.g: '%s - %s' (where the first is name, second is description)
 * @return - list of [enabled options list, descriptions of enabled options list]
 */
static List makeListOfEnabledOptions(Map optionsMap, String formatTemplate = '%s - %s') {
    List options = []
    List descriptions = []
    optionsMap.each {
        if (it.value.get('state')) {
            options.add(it.key)
            if (it.value.get('description'))
                descriptions.add(String.format(formatTemplate, it.key, it.value.description))
        }
    }
    [options, descriptions]
}

/**
 * Print event-type and message.
 *
 * @param eventNum - event type: debug, info, etc...
 * @param text - text to output
 */
// groovylint-disable-next-line MethodReturnTypeRequired, NoDef
def outMsg(Integer eventNum, String text) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) { // groovylint-disable-line
        List eventTypes = [
                '\033[0;34mDEBUG\033[0m',
                '\033[0;32mINFO\033[0m',
                '\033[0;33mWARNING\033[0m',
                '\033[0;31mERROR\033[0m']
        println String.format('%s | %s | %s', env.JOB_NAME, eventTypes[eventNum], text)
    }
}


node(env.JENKINS_NODE) {
    wrap([$class: 'TimestamperBuildWrapper']) {
        // Pipeline parameters check
        Boolean pipelineVariableNotDefined = false
        List requiredVariablesList = ['ACTION',
                                      'BAREOS_COMPONENTS',
                                      'ANSIBLE_GIT_BRANCH',
                                      'JENKINS_NODE']
        List otherVariablesList = ['SSH_SUDO_PASSWORD',
                                   'ANSIBLE_GIT_BRANCH',
                                   'BAREOS_RELEASE',
                                   'OVERRIDE_LINUX_DISTRO_VERSION',
                                   'DEBUG_MODE']
        otherVariablesList += (ActionsEnabled.install_and_add_client.state || ActionsEnabled.add_client.state) ? [
                'FILE_DAEMON_NAME',
                'BAREOS_SERVER_SSH_PASSWORD',
                'USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS',
                'USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER',
                'BAREOS_SERVER_SSH_LOGIN',
                'BAREOS_SERVER_SSH_PASSWORD'
        ] : []
        otherVariablesList += ActionsEnabled.access.state ? [
                'WEBUI_USERNAME',
                'WEBUI_PASSWORD',
                'WEBUI_PROFILE',
                'WEBUI_TLS_ENABLE'
        ] : []
        otherVariablesList += (ActionsEnabled.install.state &&
                (BareosComponentsEnabled.dir.state || BareosComponentsEnabled.dir_webui.state)) ? [
                'PREINSTALLED_POSTGRESQL',
                'POSTGRESQL_VERSION',
                'WEBUI_PROFILE',
                'INIT_BAREOS_DATABASE'
        ] : []
        otherVariablesList += (ActionsEnabled.install.state || ActionsEnabled.uninstall.state) ? [
                'IP_LIST',
                'SSH_LOGIN',
                'SSH_PASSWORD',
                'INSTALL_ADDITIONAL_BAREOS_PACKAGES'
        ] : []
        otherVariablesList += (ActionsEnabled.copy_configs.state || (BareosCopyConfigsParams.findAll { it.value })) ? [
                'CONFIGS_GIT_URL',
                'CONFIGS_GIT_BRANCH'
        ] : []
        (requiredVariablesList + otherVariablesList).each {
            pipelineVariableNotDefined = (params.containsKey(it)) ? pipelineVariableNotDefined : true
        }

        /** Update pipeline parameters */
        if (pipelineVariableNotDefined) {
            currentBuild.displayName = String.format('pipeline_parameters_update--#%s', env.BUILD_NUMBER)
            def (List bareosActionsChoices, List bareosActionsDescriptions) = makeListOfEnabledOptions(ActionsEnabled,
                    '<b>%s</b> - %s') as ArrayList
            def (List bareosComponentsChoices, List bareosComponentsDescriptions) = makeListOfEnabledOptions(
                    BareosComponentsEnabled, '<b>%s</b> - %s') as ArrayList
            def (List webuiProfilesChoices, List __) = makeListOfEnabledOptions(WebUiProfilesEnabled) as ArrayList

            List pipelineParams = [
                    string(name: 'IP_LIST',
                            description:
                                    'Space separated IP or DNS list for install/uninstall components and copy configs.',
                            defaultValue: '',
                            trim: false),
                    string(name: 'SSH_LOGIN',
                            description: String.format('%s %s',
                                    'Login for SSH connection for install/uninstall components and copy configs',
                                    '(The same for all hosts).'),
                            defaultValue: '',
                            trim: false),
                    password(name: 'SSH_PASSWORD',
                            description: String.format('%s %s',
                                    'SSH password for install/uninstall components and copy configs',
                                    '(The same for all hosts).'),
                            defaultValue: ''),
                    password(name: 'SSH_SUDO_PASSWORD',
                            description: String.format('%s %s<br>%s',
                                    'SSH sudo password or root password for install/uninstall components',
                                    'and copy configs (The same for all hosts).',
                                    'If this parameter is empy SSH_PASSWORD will be used.'),
                            defaultValue: ''),
                    choice(name: 'ACTION',
                            description: String.format('%s:<br><br>%s', 'Action to perform',
                                    bareosActionsDescriptions.join(',<br>')),
                            choices: bareosActionsChoices),
                    choice(name: 'BAREOS_COMPONENTS',
                            description: String.format('%s:<br><br>%s', 'Bareos components to install or uninstall',
                                    bareosComponentsDescriptions.join(',<br>')),
                            choices: bareosComponentsChoices),
                    choice(name: 'BAREOS_RELEASE',
                            description: 'Bareos release.<br><br><br><br>',
                            choices: ListOfBareosReleases),
                    string(name: 'OVERRIDE_LINUX_DISTRO_VERSION',
                            description: 'Override ansible distribution major version when there\'s no Bareos repo',
                            defaultValue: '',
                            trim: false)

            ] + ((ActionsEnabled.install_and_add_client.state || ActionsEnabled.add_client.state) ? [
                    string(name: 'FILE_DAEMON_NAME',
                            description: String.format('%s %s',
                                    'Name of file daemon to display on Bareos server',
                                    '(leave \'\' for FQDN or hostname).'),
                            defaultValue: '',
                            trim: false),
                    password(name: 'FILE_DAEMON_PASSWORD',
                            description: String.format('%s %s<br><br><br><br>',
                                    'Password to connect file daemon with',
                                    '(leave \'\' to generate random password).'),
                            defaultValue: ''),
                    booleanParam(name: 'USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS',
                            description: String.format('%s %s %s',
                                    'Use pipleine constants for Bareos Server SSH access for file daemon add',
                                    'and Web UI access control, otherwise set BAREOS_SERVER, BAREOS_SERVER_SSH_LOGIN',
                                    'and BAREOS_SERVER_SSH_PASSWORD (login and become are the same).'),
                            defaultValue: true),
                    string(name: 'BAREOS_SERVER',
                            description:
                                    'Bareos server IP address or DNS for file daemon add, grant/revoke Web UI access.',
                            defaultValue: '',
                            trim: false),
                    booleanParam(name: 'USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER',
                            description: String.format('%s %s', 'Use prepared on jenkins node ssh keys and config to',
                                    'connect Bareos server, otherwise uncheck and set login and password.'),
                            defaultValue: true),
                    string(name: 'BAREOS_SERVER_SSH_LOGIN',
                            description: 'Bareos Server SSH login for Bareos client add, grant/revoke Web UI access.',
                            defaultValue: '',
                            trim: false),
                    password(name: 'BAREOS_SERVER_SSH_PASSWORD',
                            description: String.format('%s<br><br><br><br>',
                                    'Bareos Server SSH password for Bareos client add, grant/revoke Web UI access.'),
                            defaultValue: '')

            ] : []) + (ActionsEnabled.access.state ? [
                    string(name: 'WEBUI_USERNAME',
                            description: 'Web UI username to create or revoke access.',
                            defaultValue: '',
                            trim: false),
                    password(name: 'WEBUI_PASSWORD',
                            description: 'Web UI password to create or revoke access.',
                            defaultValue: ''),
                    choice(name: 'WEBUI_PROFILE',
                            description: 'Web UI access profile.',
                            choices: webuiProfilesChoices),
                    booleanParam(name: 'WEBUI_TLS_ENABLE',
                            description: 'Use TLS.<br><br><br><br>',
                            defaultValue: false)

            ] : []) + ((ActionsEnabled.install.state && (BareosComponentsEnabled.dir.state ||
                    BareosComponentsEnabled.dir_webui.state)) ? [
                    booleanParam(name: 'PREINSTALLED_POSTGRESQL',
                            description: 'Already preinstalled PostgreSQL before Bareos director install.',
                            defaultValue: false),
                    choice(name: 'POSTGRESQL_VERSION',
                            description: 'Version of PostgreSQL to install.',
                            choices: ListOfPostgreSqlVersions),
                    booleanParam(name: 'INIT_BAREOS_DATABASE',
                            description: String.format('%s %s<br><br><br><br>',
                                    'Force init Bareos database (run scripts) before Bareos install',
                                    '(for CentOS 7 will run anyway).'),
                            defaultValue: false)

            ] : []) + ((ActionsEnabled.install.state || ActionsEnabled.uninstall.state) ? [
                    string(name: 'INSTALL_ADDITIONAL_BAREOS_PACKAGES',
                            description: String.format('%s<br><br><br><br>',
                                    'Space separated list of additional Bareos packages to install.'),
                            defaultValue: InstallAdditionalBareosPackagesDefaults,
                            trim: false)

            ] : []) + ((ActionsEnabled.copy_configs.state || (BareosCopyConfigsParams.findAll { it.value })) ? [
                    string(name: 'CONFIGS_GIT_URL',
                            description: 'Bareos configs git URL.',
                            defaultValue: DefaultBareosConfigsUrl,
                            trim: false),
                    string(name: 'CONFIGS_GIT_BRANCH',
                            description: 'Bareos configs git branch. Leave empty to skip configs copy.<br><br><br><br>',
                            defaultValue: DefaultBareosConfigsBranch,
                            trim: false)
            ] : []) + [
                    string(name: 'ANSIBLE_GIT_BRANCH',
                            description: 'Git branch of ansible project with bareos role.',
                            defaultValue: DefaultAsnibleGitBranch,
                            trim: false),
                    booleanParam(name: 'DEBUG_MODE',
                            description: 'Verbose output.',
                            defaultValue: false),
                    choice(name: 'JENKINS_NODE',
                            description: 'Jenkins node to execute ansible',
                            choices: NodesToExecute)

            ]
            properties([parameters(pipelineParams)])
            outMsg(1, "Pipeline parameters was successfully injected. Select 'Build with parameters' and run again.")
            currentBuild.build().getExecutor().interrupt(Result.SUCCESS) // groovylint-disable-line UnnecessaryGetter
            sleep(time: 3, unit: 'SECONDS')
        }

        /** Check required pipeline parameters was set and correct */
        Boolean errorsFound = false
        requiredVariablesList += env.ACTION.matches('.*access$') ? [] : ['IP_LIST', 'SSH_LOGIN', 'SSH_PASSWORD']
        requiredVariablesList += (env.ACTION.matches('.*(access|add_client)') &&
                !env.USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS.toBoolean()) ? [
                'BAREOS_SERVER',
                'BAREOS_SERVER_SSH_LOGIN',
                'BAREOS_SERVER_SSH_PASSWORD'
        ] : []
        requiredVariablesList += env.ACTION =~ 'access' ? ['WEBUI_USERNAME'] : []
        requiredVariablesList += env.ACTION == 'access' ? ['WEBUI_PASSWORD', 'WEBUI_PROFILE'] : []
        requiredVariablesList.each {
            if (params.containsKey(it) && !env[it.toString()]?.trim()) {
                errorsFound = true
                outMsg(3, String.format('%s is undefined for current job run. Please set then run again.', it))
            }
        }

        errorsFound = ((ActionsEnabled.get(env.ACTION) && !ActionsEnabled[env.ACTION as String].state) ||
                (BareosComponentsEnabled.get(env.BAREOS_COMPONENTS) &&
                        !BareosComponentsEnabled[env.BAREOS_COMPONENTS as String].state)) ? true : errorsFound
        errorsFound = (env.WEBUI_PROFILE?.trim() && env.ACTION == 'access') &&
                (!WebUiProfilesEnabled.get(env.WEBUI_PROFILE) ||
                        !WebUiProfilesEnabled[env.WEBUI_PROFILE as String].state) ? true : errorsFound

        if (env.ACTION =~ 'add_client' && env.BAREOS_COMPONENTS != 'fd')
            outMsg(2, 'Only file daemon add to server supported in this ansible role. File daemon will be added.')
        if (!env.ACTION.matches('.*access$') && !env.SSH_SUDO_PASSWORD?.trim()) {
            outMsg(2, 'SSH_SUDO_PASSWORD wasn\'t set, will be taken from SSH_PASSWORD.')
            env.SSH_SUDO_PASSWORD = env.SSH_PASSWORD
        }
        if (errorsFound)
            error 'Missing or incorrect pipeline parameter(s).'

        /** Handling Build display name */
        String bareosServer = String.format('_to_%s', (env.USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS
                .toBoolean()) ? BareosServerHost : env.BAREOS_SERVER)
        String bareosActionSubject = String.format('%s%s%s',
                (env.ACTION =~ 'access' ? String.format('user_%s%s', env.WEBUI_USERNAME, bareosServer) : ''),
                (env.ACTION =~ 'install' ? env.BAREOS_COMPONENTS : ''),
                (env.ACTION.matches('(.+)?add_client$') ? bareosServer : ''))
        currentBuild.displayName = String.format('%s__%s--#%s', env.ACTION, bareosActionSubject, env.BUILD_NUMBER)

        /** Cleanup ssh keys, install ansible collection */
        List hostsToClean = env.IP_LIST.trim().tokenize() + ((params.containsKey(BAREOS_SERVER) &&
                !env.USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER.toBoolean()) ? [env.BAREOS_SERVER] : [])
        hostsToClean.findAll { it }.each {
            List itemsToClean = (it.matches('^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$')) ? [it] : [it] +
                    [sh(script: String.format('getent hosts %s | cut -d\' \' -f1', it), returnStdout: true).toString()]
            itemsToClean.each { host ->
                if (host?.trim()) sh String.format('ssh-keygen -f "%s/.ssh/known_hosts" -R %s', env.HOME, host)
            }
        }
        String collectionInstallScript = String.format('%s %s %s', 'ansible-galaxy collection install',
                AnsibleCollectionName, ForceInstallAnsibleCollection ? '-f' : '')
        if (AnsibleGitRepoUrl.trim()) {
            dir('ansible') {
                sh 'sudo rm -rf *'
                git(branch: env.ANSIBLE_GIT_BRANCH, credentialsId: GitCredentialsId, url: AnsibleGitRepoUrl)
                collectionInstallScript = String.format('%s; %s %s', 'ansible-galaxy collection build',
                        'ansible-galaxy collection install $(ls -1 | grep ".tar.gz")',
                        ForceInstallAnsibleCollection ? '-f' : '')
                if (sh(returnStdout: true, returnStatus: true, script: collectionInstallScript) != 0)
                    error 'Unable to install ansible collection.'
            }
        }

        List ansibleActions = (env.ACTION == 'install_and_add_client') ? ['install', 'add_client'] : env.ACTION
                .tokenize()
        ansibleActions.each {
            /** Parsing template parameters bind */
            String ansibleInventoryFirstPart = ''
            Map modifiableParams = params + [
                    ACTION                   : it,
                    ansible_hosts_group      : 'all',
                    ansible_group_hosts      : env.IP_LIST.replaceAll(' ', '\n'),
                    ansible_user             : env.SSH_LOGIN,
                    ansible_password         : env.SSH_PASSWORD,
                    ansible_become_password  : env.SSH_SUDO_PASSWORD,
                    ansible_collection       : AnsibleCollectionName,
                    home_folder              : env.HOME,
                    private_ssh_key_file_name: SshPrivateKeyFilename,
                    ansible_hosts_condition  : true,
                    INIT_BAREOS_DATABASE     : (env.INIT_BAREOS_DATABASE?.trim()) ? env.INIT_BAREOS_DATABASE : false
            ]
            modifiableParams += [add_component_name_parameter_line: env.FILE_DAEMON_NAME.trim() ?
                    String.format('add_component_name: %s', env.FILE_DAEMON_NAME) : '']
            modifiableParams += [add_component_password_parameter_line: env.FILE_DAEMON_PASSWORD.trim() ?
                    String.format('add_component_password: %s', env.FILE_DAEMON_PASSWORD) : '']
            String ansibleInventoryOptions = AnsibleInventoryTemplate + AnsibleInventoryPasswordConnectionOptions

            if (modifiableParams.ACTION.matches('.*(access|add_client)$')) {
                if (modifiableParams.ACTION == 'add_client') {
                    modifiableParams.ansible_hosts_group = 'clients'
                    ansibleInventoryFirstPart = new StreamingTemplateEngine().createTemplate(ansibleInventoryOptions)
                            .make(modifiableParams).toString()
                    modifiableParams += [
                            ansible_hosts_group    : 'server',
                            ansible_hosts_condition: 'inventory_hostname in groups["clients"]',
                            add_component_server   : '"{{ groups.server[0] }}"',
                            BAREOS_COMPONENTS      : 'fd'
                    ]
                }

                modifiableParams += (env.USE_PIPELINE_CONSTANTS_FOR_BAREOS_SERVER_ACCESS.toBoolean() ? [
                        ansible_group_hosts    : BareosServerHost,
                        ansible_user           : BareosServerSshLogin,
                        ansible_password       : BareosServerSshPassword,
                        ansible_become_password: BareosServerSshPassword
                ] : [
                        ansible_group_hosts    : env.BAREOS_SERVER,
                        ansible_user           : env.BAREOS_SERVER_SSH_LOGIN,
                        ansible_password       : env.BAREOS_SERVER_SSH_PASSWORD,
                        ansible_become_password: env.BAREOS_SERVER_SSH_PASSWORD
                ])
                ansibleInventoryOptions = AnsibleInventoryTemplate + (env.USE_SSH_KEY_TO_CONNECT_BAREOS_SERVER
                        .toBoolean() ? AnsibleInventorySshKeyConnectionOptions :
                        AnsibleInventoryPasswordConnectionOptions)
            }

            /** Copy Bareos configs */
            if ((BareosCopyConfigsParams[modifiableParams.ACTION] && modifiableParams.ACTION == 'copy_configs') ||
                    (BareosCopyConfigsParams[modifiableParams.BAREOS_COMPONENTS] &&
                            modifiableParams.ACTION =~ 'install'))
                if (env.CONFIGS_GIT_URL?.trim() && env.CONFIGS_GIT_BRANCH?.trim()) {
                    dir('bareos') {
                        sh 'sudo rm -rf *'
                        try {
                            git(branch: env.CONFIGS_GIT_BRANCH,
                                    credentialsId: GitCredentialsId,
                                    url: env.CONFIGS_GIT_URL)
                            modifiableParams.bareos_configs_to_copy = String.format(
                                    '[{ source: "%s/bareos/%s", destination: "/etc", owner: bareos, group: bareos }]',
                                    env.WORKSPACE, BareosConfigsSouthRelativePath)
                        } catch (ignored) {
                            outMsg(3, 'Cloning Bareos configs failed.')
                        }
                    }
                } else {
                    outMsg(2, String.format('Bareos configs copy will be skiped: %s',
                            'CONFIGS_GIT_URL and/or CONFIGS_GIT_BRANCH wasn\'t set.'))
                }

            /** Templating playbook and inventory, run ansible */
            String ansibleInventoryText = new StreamingTemplateEngine()
                    .createTemplate(ansibleInventoryFirstPart + ansibleInventoryOptions).make(modifiableParams)
            // groovylint-disable-next-line UnnecessaryCollectCall
            List playbookVariablesMention = AnsibleDefaultPlaybookTemplate.findAll('\\$[0-9a-zA-Z_]+').collect {
                it.replace('$', '')
            }
            Map ansibleVariablesBinding = playbookVariablesMention.collectEntries { [it, ''] } + modifiableParams
            String ansiblePlaybookText = new StreamingTemplateEngine().createTemplate(AnsibleDefaultPlaybookTemplate)
                    .make(ansibleVariablesBinding)
            String stageName = (modifiableParams.ACTION =~ 'install') ?
                    String.format('%s_%s', modifiableParams.ACTION, modifiableParams.BAREOS_COMPONENTS) :
                    modifiableParams.ACTION
            stage(stageName) {
                try {
                    writeFile file: 'inventory.ini', text: ansibleInventoryText
                    writeFile file: 'execute.yml', text: ansiblePlaybookText
                    outMsg(1, String.format('Running from:\n%s\n%s', ansiblePlaybookText, ('-' * 32)))
                    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
                        sh String.format('%s %s ansible-playbook %s %s -i %s', 'ANSIBLE_LOAD_CALLBACK_PLUGINS=1',
                                'ANSIBLE_STDOUT_CALLBACK=yaml ANSIBLE_FORCE_COLOR=true', env.DEBUG_MODE.toBoolean() ?
                                '-vvvv' : '', 'execute.yml', 'inventory.ini')
                    }
                } catch (Exception error) {
                    outMsg(3, String.format('Running ansible failed: %s', String.format('Line %s: %s',
                            error.stackTrace.head().lineNumber, StackTraceUtils.sanitize(error))))
                    sleep(time: 2, unit: 'SECONDS')
                    currentBuild.result = 'FAILURE'
                }
            }
        }
    }
}

