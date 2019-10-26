# How to run Xorg applications from Jenkins pipeline. ##############

This example illustrates how to prepare linux system to run Xorg for GUI tests from Jenkins pipelines. In example below we install openbox at junkins node, Ubuntu Server 16.04 (actually you can use any latest distro). Then run jenkins pipeline on this node to connect RDP for several seconds. You can change RDP connections (a several bash lines) on your own code (e.g. run [Selenium](https://www.seleniumhq.org/) or other GUI-related testing).


# Requirments:

1. Jenkins master node installed.
2. (Additional) Jenkins node (or master) with Ubuntu 16.04 Server (or later): to install Xorg and execute Jenkins pipeline here.
3. (Additional) Gitlab: to clone Jenkins pipeline code from.


## Install openbox to Jenkins node

First of all you should add jenkins user to sudo sudoers to passwordless `sudo` execution:
```bash
sudo usermod -aG sudo jenkins
```
In example bellow we will be able to run any command, but you can add single bash commands. So add into `/etc/sudoers` the next lines
```
# Allow members of group sudo to execute any command
jenkins         ALL=(ALL)       NOPASSWD: ALL
```

One of the easiest way is to install Xorg together with [openbox](http://openbox.org) to avoid editing lots of configs:
```bash
sudo apt update && sudo apt upgrade
sudo apt install xorg openbox
```
Then you will need to create a file:
```bash
cat ~/.xinitrc
```
containing next lines:
```bash
#!/bin/bash
exec openbox-session
```
Finally copy the default config files:
```bash
mkdir ~/.config
mkdir ~/.config/openbox
cp /etc/xdg/openbox/autostart.sh ~/.config/openbox/
cp /etc/xdg/openbox/menu.xml ~/.config/openbox/
cp /etc/xdg/openbox/rc.xml ~/.config/openbox/
```
Now you can run X session:
```bash
sudo startx
```

The point of this method is to run Xorg before your custom tasks then kill X session on complete. In this case you don't need to copy `/etc/xdg/openbox/autostart.sh`, otherwise put them in rc.local or create systemd unit. Try execute on jenkins node with Xorg something like this:
```bash
#!/bin/bash

su - jenkins
set -e; sudo startx &
DISPLAY=:0; export DISPLAY; sudo xhost +

# ...
# do what you want in X session here
# ...

sudo killall Xorg
```


## Create jenkins pipeline

Now create jenkins pipeline from the last bash example or use [this groovy example](https://github.com/alexanderbazhenoff/scripts-various/blob/master/jenkins/xorg-pipelines-example/xorg-jenkins-pipeline.groovy). You can put your pipeline source code from your web browser to pipeline settings, otherwise use 'Pipeline script from SCM' (e.g. to clone from your git project).

Assuming on your jenkins node you have only one video output and one Xorg pipeline. If yes, you also need: 
- set 'Do not allow concurrent builds' in your pipleine settings and select 'Throttle Concurrent Builds'
- select 'Throttle this project alone'
- set 'Maximum Concurrent Builds Per Node' to 1.

Please note, to connect RDP sessions using our [groovy example](https://github.com/alexanderbazhenoff/scripts-various/blob/master/jenkins/xorg-pipelines-example/xorg-jenkins-pipeline.groovy) you'll also need to install `freerdp-x11`:
```bash
sudo apt install freerdp-x11
```
