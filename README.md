Repository for scripts to install ardupilot development environment inside proxmox containers

new proxmox container based on debian 11

login as root


```
apt install sudo git -y
git clone https://github.com/nkruzan/ardupilot-proxmox-containers.git
cd ardupilot-proxmox-containers
./install-ardupilot-dev-env.sh
```
 You will be prompted for the following:
 1. username
 > this is for new user that will be created
 2. password
 > this is for the new user that will be created
 3. Use ArduPilot repo from github? (Y/N)
 > y = use ArduPilot repo from github
 > n = you get prompted to enter another github *username*
 4. Use branch master? (Y/N)
 > y = use branch master
 > n = you get prompted to enter branch *name*
 5. password for sudo
 > this is the password you just created
 6. Install ESP32 (Y/N)
 > y = installs esp32 tools
 > n = does not install esp32 tools
 7. Install Custom Build Server? (Y/N)
 > y = same prompt as 3 above for repo to use
 > n = do not install
 8. Enter dns name for server:
 > server name (used for apache2 config)
 9. Reboot (Y/N)
 > y = reboot, required if install custom build server
 > n = do not reboot
 
 this is only tested and known to work on new debian 11 container.
 
