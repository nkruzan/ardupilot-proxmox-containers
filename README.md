Repository for scripts to install ardupilot development environment inside proxmox containers

new proxmox container based on debian 11
login as root

apt install sudo git -y
git clone https://github.com/nkruzan/ardupilot-proxmox-containers.git
cd ardupilot-proxmox-containers
chmod +x install-ardupilot-dev-env.sh
./install-ardupilot-dev-env.sh

