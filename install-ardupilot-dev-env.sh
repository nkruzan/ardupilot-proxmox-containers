#!/bin/bash
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" "$username"
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may run this script (it adds user)"
	exit 2
fi

egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
    echo "adding $username to sudoers..."
    echo "$username  ALL=(ALL:ALL) ALL" >> /etc/sudoers

    #we dont want the password to be in the logs...
    export HISTIGNORE='*sudo -S*'

    #user was successfully added continue here as new user
    echo "$password" | sudo -S -i -u "$username" bash << EOF
sudo apt clean
sudo apt update
sudo apt upgrade -y 
#git clone https://github.com/ArduPilot/ardupilot.git
git clone https://github.com/nkruzan/ardupilot.git
cd ardupilot
git checkout pr/bullseye-install
git submodule update --init --recursive
Tools/environment_install/install-prereqs-ubuntu.sh -y
echo "Starting SITL"
cd ArduPlane
sim_vehicle.py -w
EOF


fi