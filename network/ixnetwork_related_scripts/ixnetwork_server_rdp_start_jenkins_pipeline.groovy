#!/usr/bin/env groovy


/**
 * Connect RDP sessions to IxNetwork Server VM to run IxNetwork server (API)
 * Writen by Aleksandr Bazhenov, October 2019.

 * This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
 * https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE
 */


final String IxNetworkRdpHost = 'ixnetwork.domain'
final String IxNetworkRdpPass = 'some_password'
final String XfreerdpNode = 'node.domain'
final List UserList = ['jenkins', 'jenkins2']


/**
 * Kill any Xorg processes.
 */
def killXorgProcesses() {
    outMsg('Kill Xorg processes')
    sh '''!/usr/bin/env bash

        listProc() {
          (ps aux | grep "/usr/lib/xorg/Xorg" | grep -v "grep" | awk -F ' ' '{print $2}') || true
        }

        if [[ -n "$(listProc)" ]]; then
          sudo kill -8 $(listProc)
        fi
        '''
}

/**
 * Print Message.
 *
 * @param msg - message to output
 */
def outMsg(String msg) {
    println String.format('%s | %s...', env.JOB_NAME, msg)
}


node(XfreerdpNode) {
    wrap([$class: 'TimestamperBuildWrapper']) {
        killXorgProcesses()
        sh 'set -e; sudo startx &'

        UserList.each {
            outMsg(String.format('Connecting to %s for %s', IxNetworkRdpHost, it))
            env.RDP_PASS = IxNetworkRdpPass
            sh String.format('''#!/usr/bin/env bash
                DISPLAY=:0; export DISPLAY; sudo xhost +
                set -e
                sudo xfreerdp /v:$%s /u:%s /p:$RDP_PASS /cert-ignore &
                set +e
                sleep 10
                sudo kill -8 $(ps aux | grep xfreerdp | grep "%s" | awk -F ' ' '{print $2}')
                ''', IxNetworkRdpHost, it, IxNetworkRdpHost)
        }

        killXorgProcesses()
        outMsg('All done.')
    }
}
