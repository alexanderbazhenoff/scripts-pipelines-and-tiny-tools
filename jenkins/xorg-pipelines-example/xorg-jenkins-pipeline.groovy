#!/usr/bin/env groovy


/**
* Example to show how to use X session jenkins pipleine.
* - Start X server,
* - Connect RDP session from xfrerdp,
* - kill X session.
*/


// Node name with Xorg installed.
def XorgNodeName = 'master'

// RDP credentials
def RDPuser = 'Administrator'
def RDPhost = 'host.domain'
def RDPpass = 'password'


/**
* Kill any Xorg processes.
*/
def prockillXorg() {
    sh '''#!/bin/bash
        
        listProc () {
            ps aux | grep "/usr/lib/xorg/Xorg" | grep -v "grep" | awk -F ' ' '{print $2}'
        }

        if [[ $(listProc) ]]; then
            sudo kill -8 $(listProc)
        fi
        '''
}


node(XorgNodeName) {
    // Just a wrapper to print timestamps in console output of jenkins pipeline
    wrap([$class: 'TimestamperBuildWrapper']) {
        prockillXorg()
        // Start Xorg in background
        sh 'set -e; sudo startx &'

        env.RDP_USER = RDPuser
        env.RDP_HOST = RDPhost
        env.RDP_PASS = RDPpass
        sh '''#!/bin/bash

            DISPLAY=:0; export DISPLAY; sudo xhost +

            # Connect RDP here (you can exexute your custom X session code instead)
            set -e
            sudo xfreerdp /v:$RDP_HOST /u:$RDP_USER /p:$RDPpass /cert-ignore &
            set +e

            # Wait and close RDP connection
            sleep 10
            sudo kill -8 $(ps aux | grep xfreerdp | grep $RDP_HOST | awk -F ' ' '{print $2}')
            '''

        prockillXorg()
    }
}
