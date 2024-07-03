#!/usr/bin/env groovy


/**
 * Show dhcp leases info from isc-dhcp-sever, or a tiny pipeline-wrapper for python script:
 * https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/tree/master/network/get_dhcpd_leases
 *
 * This Source Code Form is subject to the terms of the BSD 3-Clause License.
 * If a copy of the source distributed without this file, you can obtain one at:
 * https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE
 */


// Start jenkins node where git clone (and optional all required keys for ssh cloning)
final String StartNode = 'master'

// Jenkins node with isc-dhcp-server to execute on, e.g.: dhcpd-server.domain
final String ExecutionNode = 'gate'

// Repo URL of 'get_dhcpd_leases.py' script, e.g: 'git@github.com:alexanderbazhenoff/various-scripts.git'
final String GitProjectUrlOfTheScript = 'https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools.git'

// Full path inside the repo to run 'get_dhcpd_leases.py' script
final String ScriptPathInsideTheRepo = 'network/get_dhcpd_leases/get_dhcpd_leases.py'

// Repo branch
final String GitScriptBranch = 'restructured'

// Credentials to access repo (for ssh cloning), e.g. 'a222b01a-230b-1234-1a12345678b9'
final String GitCredentials = ''


node(StartNode) {
    git branch: GitScriptBranch, credentialsId: GitCredentials, url: GitProjectUrlOfTheScript
    stash name: 'script', includes: ScriptPathInsideTheRepo
    node(ExecutionNode) {
        unstash 'script'
        sh String.format('python3 ./%s', ScriptPathInsideTheRepo)
    }
}
