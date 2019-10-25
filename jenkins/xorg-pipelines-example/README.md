# Run Xorg jenkins pipeline.

This example illustrates how to prepare linux system to run Xorg and run gui tests from Jenkins pipelines. In example below we install openbox at Ubuntu Server 16.04 (actually you can use any latest distro) to run jenkins pipeline that connects to RDP for several seconds. You can change RDP connections (a several bash lines) on your own (e.g. run [Selenium](https://www.seleniumhq.org/) or other GUI-related testing).

## Install openbox

Before you start add jenkins user to sudo sudoers:
```bash
sudo usermod -aG sudo jenkins
```
Allow them to execute commands without password (in example bellow we will be able to run any command, but you can add custom). So add into `/etc/sudoers` the next lines
```
# Allow members of group sudo to execute any command
jenkins         ALL=(ALL)       NOPASSWD: ALL
```

One of the easiest way is to install Xorg with [openbox](http://openbox.org):
```bash
sudo apt update && sudo apt upgrade
sudo apt install xorg openbox
```
Then you will need to create a file:
```bash
cat ~/.xinitrc
```
containing:
```bash
#!/bin/bash
exec openbox-session
```
Copy the default config files:
```bash
mkdir ~/.config
mkdir ~/.config/openbox
cp /etc/xdg/openbox/autostart.sh ~/.config/openbox/
cp /etc/xdg/openbox/menu.xml ~/.config/openbox/
cp /etc/xdg/openbox/rc.xml ~/.config/openbox/
```
The point of this method is to run Xorg before your custom tasks then kill X session on complete:
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
The point of this method is to run Xorg before your custom tasks then kill X session on complete. In this case you don't need to copy `/etc/xdg/openbox/autostart.sh`, otherwise put them in rc.local or create systemd unit.

## Create jenkins pipeline

Now create jenkins pipeline with the last bash example or use [this groovy example](https://github.com/alexanderbazhenoff/scripts-various/blob/master/jenkins/xorg-pipelines-example/xorg-jenkins-pipeline.groovy) with 'Pipeline script from SCM' to clone from your git project.

Asuming you have only one video output and GUI-releated task on your system. So you also need: 
- set 'Do not allow concurrent builds' in your pipleine settings and select 'Throttle Concurrent Builds'
- select 'Throttle this project alone'
- set 'Maximum Concurrent Builds Per Node' to 1.

To connect RDP sessions from groovy example you'll also need to install `freerdp-x11`:
```bash
sudo apt install freerdp-x11
```