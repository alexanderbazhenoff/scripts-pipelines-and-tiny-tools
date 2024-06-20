#!/usr/bin/env groovy

/**
 * A jenkins pipeline for installing and customizing zabbix agent, or a wrapper for
 * alexanderbazhenoff.linux.zabbix_agent ansible role:
 * https://github.com/alexanderbazhenoff/ansible-collection-linux/tree/main/roles/zabbix_agent
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


import org.codehaus.groovy.runtime.StackTraceUtils
import groovy.text.StreamingTemplateEngine
import hudson.model.Result


// Repo URL of 'alexanderbazhenoff.linux' ansible collection repo.
final String AnsibleGitRepoUrl = 'https://github.com/alexanderbazhenoff/ansible-collection-linux.git'

// Repo branch.
final String AnsibleGitDefaultBranch = 'main'
// If you wish to clone from non-public repo, or use ssh cloning. E.g: 'a222b01a-230b-1234-1a12345678b9'.
final String AnsibleGitCredentialsId = ''

// Set your ansible installation name from jenkins settings.
final List NodesToExecute = ['domain.com']

// List of Zabbix version to select in ZABBIX_AGENT_RELEASE pipeline parameter.
final List ZabbixAgentVersions = ['5.0', '5,5', '6.0', '4.0']


// Playbook template, inventory files and ansible repo path.
final String AnsibleDefaultPlaybookTemplate = '''\
---
- hosts: all
  become: true
  become_method: sudo
  tasks:
    - name: Include zabbix_agent role
      ansible.builtin.include_role:
        name: alexanderbazhenoff.linux.zabbix_agent
      vars:
        zabbix_release: $zabbix_release
        install_v2_agent: $install_v2_agent
        customize_agent: $network_bridge_name
        customize_agent_only: $customize_agent_only
        clean_install: $clean_install
'''

final String AnsibleServersPassivePlaybookTemplate = '''\
  zabbix_servers_passive: $servers_passive
'''

final String AnsibleServersActivePlaybookTemplate = '''\
  zabbix_servers_passive: $servers_active
'''

final String AnsibleInventoryTemplate = '''\
[all]
$hosts_list
[all:vars]
ansible_connection=ssh
ansible_become_user=root
ansible_ssh_common_args='-o StrictHostKeyChecking=no\'
ansible_ssh_user=$ssh_user
ansible_ssh_pass=$ssh_password
ansible_become_pass=$ssh_become_password
'''


/**
 * More readable exceptions with line numbers.
 *
 * @param error - Exception error.
 */
static String readableError(Throwable error) {
    String.format('Line %s: %s', error.stackTrace.head().lineNumber, StackTraceUtils.sanitize(error))
}

/**
 * Print event-type and message.
 *
 * @param eventNum - event type: debug, info, etc...
 * @param text - text to output
 */
// groovylint-disable-next-line MethodReturnTypeRequired, NoDef
def outMsg(Integer eventNum, String text) {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {  // groovylint-disable-line DuplicateMapLiteral
        List eventTypes = [
                '\033[0;34mDEBUG\033[0m',
                '\033[0;32mINFO\033[0m',
                '\033[0;33mWARNING\033[0m',
                '\033[0;31mERROR\033[0m']
        println String.format('%s | %s | %s', env.JOB_NAME, eventTypes[eventNum], text)
    }
}

/**
 * Run ansible role/playbook with (optional) ansible-galaxy collections install.
 *
 * @param ansiblePlaybookText - text content of ansible playbook/role.
 * @param ansibleInventoryText - text content of ansible inventory file.
 * @param ansibleGitlabUrl - git URL of ansible project to clone and run.
 * @param ansibleGitlabBranch - git branch of ansible project.
 * @param gitCredentialsID - git credentials ID.
 * @param ansibleExtras - (optional) extra params for playbook running.
 * @param ansibleCollections - (optional) list of ansible-galaxy collections dependencies which will be installed before
 *                             running the script. Collections should be placed in ansible gitlab project according to
 *                             ansible-galaxy directory layout standards. If variable wasn't pass (empty) the roles
 *                             will be called an old-way from a playbook placed in 'roles/execute.yml'. It's only for
 *                             the backward capability.
 * @return - success (true when ok)
 */
Boolean runAnsible(String ansiblePlaybookText, String ansibleInventoryText, String ansibleGitlabUrl,
                   String ansibleGitlabBranch, String gitCredentialsID, String ansibleExtras = '') {
    try {
        dir('ansible') {
            sh 'sudo rm -rf ./*'
            git branch: ansibleGitlabBranch, credentialsId: gitCredentialsID, url: ansibleGitlabUrl
            if (sh(returnStdout: true, returnStatus: true, script: '''ansible-galaxy collection build
                        ansible-galaxy collection install $(ls -1 | grep ".tar.gz") -f''') != 0)
                error 'There was an error building and installing ansible collection.'
            writeFile file: 'inventory.ini', text: ansibleInventoryText
            writeFile file: 'execute.yml', text: ansiblePlaybookText
            outMsg(1, String.format('Running from:\n%s\n%s', ansiblePlaybookText, ('-' * 32)))
            sh String.format('%s %s ansible-playbook %s -i %s %s', 'ANSIBLE_LOAD_CALLBACK_PLUGINS=1',
                    'ANSIBLE_STDOUT_CALLBACK=yaml ANSIBLE_FORCE_COLOR=true', 'execute.yml', 'inventory.ini',
                    ansibleExtras)
        }
    } catch (Exception err) {
        outMsg(3, String.format('Running ansible failed: %s', readableError(err)))
        return false
    } finally {
        sh 'sudo rm -f ansible/inventory.ini'
    }
    true
}


node(env.JENKINS_NODE) {
    wrap([$class: 'TimestamperBuildWrapper']) {
        /** Pipeline parameters check and inject (first run). */
        Boolean pipelineVariableNotDefined = false
        // groovylint-disable-next-line UnnecessaryGetter
        Map envVars = env.getEnvironment().collectEntries { k, v -> [k, v] }
        List requiredVariablesList = ['IP_LIST',
                                      'SSH_LOGIN',
                                      'SSH_PASSWORD',
                                      'ZABBIX_AGENT_RELEASE',
                                      'ANSIBLE_GIT_URL',
                                      'ANSIBLE_GIT_BRANCH']
        List otherVariablesList = ['SSH_SUDO_PASSWORD',
                                   'INSTALL_AGENT_V2',
                                   'CUSTOMIZE_AGENT',
                                   'CUSTOMIZE_AGENT_ONLY',
                                   'CLEAN_INSTALL',
                                   'CUSTOM_PASSIVE_SERVERS_IPS',
                                   'CUSTOM_ACTIVE_SERVERS_IPS',
                                   'JENKINS_NODE',
                                   'DEBUG_MODE']
        (requiredVariablesList + otherVariablesList).each {
            pipelineVariableNotDefined = (envVars.containsKey(it)) ? pipelineVariableNotDefined : true
        }
        if (pipelineVariableNotDefined) {
            properties([
                    parameters(
                            [string(name: 'IP_LIST',
                                    description: 'Space separated IP or DNS list.',
                                    trim: true),
                             string(name: 'SSH_LOGIN',
                                     description: 'Login for SSH connection (The same for all hosts).',
                                     trim: true),
                             password(name: 'SSH_PASSWORD',
                                     description: 'SSH password (The same for all hosts).'),
                             password(name: 'SSH_SUDO_PASSWORD',
                                     description: String.format('%s<br>%s<br><br><br>',
                                             'SSH sudo password or root password (The same for all hosts).',
                                             'If this parameter is empy SSH_PASSWORD will be used.')),
                             booleanParam(name: 'INSTALL_AGENT_V2',
                                     description: 'Install Zabbix agent v2 when possible.',
                                     defaultValue: true),
                             booleanParam(name: 'CUSTOMIZE_AGENT',
                                     description: 'Configure Zabbix agent config for service discovery.',
                                     defaultValue: true),
                             booleanParam(name: 'CUSTOMIZE_AGENT_ONLY',
                                     description: 'Configure Zabbix agent for service discovery without install.',
                                     defaultValue: false),
                             choice(name: 'ZABBIX_AGENT_RELEASE',
                                     description: 'Zabbix agent version.',
                                     choices: ZabbixAgentVersions),
                             booleanParam(name: 'CLEAN_INSTALL',
                                     description: 'Remove old versions of Zabbix agent with configs first.<br><br><br>',
                                     defaultValue: true),
                             string(name: 'CUSTOM_PASSIVE_SERVERS_IPS',
                                     description: String.format('%s<br>%s %s',
                                             'Custom Zabbix Servers Passive IP(s).',
                                             'Split this by comma for several IPs. Leave this field blank for default',
                                             'Zabbix Servers IPs.'),
                                     defaultValue: '',
                                     trim: false),
                             string(name: 'CUSTOM_ACTIVE_SERVERS_IPS',
                                     description: String.format('%s<br>%s %s<br><br><br><br><br>',
                                             'Custom Zabbix Servers Active IP(s) and port(s), e.g.: A.B.C.D:port',
                                             'Split this by comma for several IPs. Leave this field blank for default',
                                             'IPs.'),
                                     defaultValue: '',
                                     trim: false),
                             string(name: 'ANSIBLE_GIT_URL',
                                     description: 'Gitlab URL of ansible project with install_zabbix role.',
                                     defaultValue: AnsibleGitRepoUrl,
                                     trim: true),
                             string(name: 'ANSIBLE_GIT_BRANCH',
                                     description: 'Gitlab branch of ansible project with install_zabbix role.',
                                     defaultValue: AnsibleGitDefaultBranch,
                                     trim: true),
                             choice(name: 'JENKINS_NODE',
                                     description: 'List of possible jenkins nodes to execute.',
                                     choices: NodesToExecute),
                             booleanParam(name: 'DEBUG_MODE', defaultValue: false)]
                    )
            ])
            outMsg(1,
                    "Pipeline parameters was successfully injected. Select 'Build with parameters' and run again.")
            currentBuild.build().getExecutor().interrupt(Result.SUCCESS) // groovylint-disable-line UnnecessaryGetter
            sleep(time: 3, unit: 'SECONDS')
        }

        /** Check and handling required pipeline parameters */
        Boolean errorsFound = false
        requiredVariablesList.each {
            if (params.containsKey(it) && !env[it.toString()]?.trim()) {
                errorsFound = true
                outMsg(3, String.format('%s is undefined for current job run. Please set then run again.', it))
            }
        }
        if (errorsFound)
            error 'Missing or incorrect pipeline parameter(s).'
        if (!env.SSH_SUDO_PASSWORD?.trim()) {
            outMsg(2, 'SSH_SUDO_PASSWORD wasn\'t set, will be taken from SSH_PASSWORD.')
            env.SSH_SUDO_PASSWORD = env.SSH_PASSWORD
        }

        /** Parameters bind and templating playbook and inventory */
        Map ansiblePlaybookVariableBinding = [
                install_v2_agent      : env.INSTALL_AGENT_V2,
                network_bridge_name   : env.CUSTOMIZE_AGENT,
                customize_agent_only  : env.CUSTOMIZE_AGENT_ONLY,
                clean_install         : env.CLEAN_INSTALL,
                zabbix_release        : env.ZABBIX_AGENT_RELEASE
        ]
        if (env.CUSTOM_PASSIVE_SERVERS_IPS?.trim()) {
            println String.format('Found custom active zabbix server(s): %s', env.CUSTOM_PASSIVE_SERVERS_IPS)
            AnsibleDefaultPlaybookTemplate += AnsibleServersPassivePlaybookTemplate
            ansiblePlaybookVariableBinding += [servers_passive: env.CUSTOM_PASSIVE_SERVERS_IPS]
        }
        if (env.CUSTOM_ACTIVE_SERVERS_IPS?.trim()) {
            println String.format('Found custom passive zabbix server(s): ', env.CUSTOM_PASSIVE_SERVERS_IPS)
            AnsibleDefaultPlaybookTemplate += AnsibleServersActivePlaybookTemplate
            ansiblePlaybookVariableBinding += [servers_active: env.CUSTOM_ACTIVE_SERVERS_IPS]
        }
        String ansiblePlaybookText = new StreamingTemplateEngine().createTemplate(AnsibleDefaultPlaybookTemplate)
                .make(ansiblePlaybookVariableBinding)
        Map ansibleInventoryVariableBinding = [
                hosts_list         : env.IP_LIST.replaceAll(' ', '\n'),
                ssh_user           : env.SSH_LOGIN,
                ssh_password       : env.SSH_PASSWORD,
                ssh_become_password: env.SSH_SUDO_PASSWORD
        ]
        String ansibleInventoryText = new StreamingTemplateEngine().createTemplate(AnsibleInventoryTemplate)
                .make(ansibleInventoryVariableBinding)

        /** Clean SSH hosts fingerprints from ~/.ssh/known_hosts */
        env.IP_LIST.tokenize().each {
            sh String.format('ssh-keygen -f "%s/.ssh/known_hosts" -R %s', env.HOME, it)
            // groovylint-disable-next-line UnnecessaryToString
            String ipAddress = sh(script: String.format('getent hosts %s | cut -d\' \' -f1', it), returnStdout: true)
                    .toString()
            if (ipAddress?.trim())
                sh String.format('ssh-keygen -f "%s/.ssh/known_hosts" -R %s', env.HOME, ipAddress)
        }

        // Run ansible role
        String ansibleVerbose = (env.DEBUG_MODE.toBoolean()) ? '-vvvv' : ''
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
            if (!runAnsible(ansiblePlaybookText, ansibleInventoryText, env.ANSIBLE_GIT_URL as String,
                    env.ANSIBLE_GIT_BRANCH as String, AnsibleGitCredentialsId, ansibleVerbose))
                error 'Ansible playbook execution failed.'
        }
    }
}
