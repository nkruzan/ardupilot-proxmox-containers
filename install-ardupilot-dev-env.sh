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
mkdir base
cd base
#git clone https://github.com/ArduPilot/ardupilot.git
git clone https://github.com/nkruzan/ardupilot.git
cd ardupilot
#git checkout pr/bullseye-install
git submodule update --init --recursive
Tools/environment_install/install-prereqs-ubuntu.sh -y
#echo "Starting SITL"
#cd ArduPlane
#sim_vehicle.py -w
EOF


fi

while true; do
    read -r -p "Install Custom Build Server? (Y/N): " answer
    case $answer in
        [Yy]* ) read -r -p "Enter dns name for server:" servername
		echo "$password" | sudo -S -i -u "$username" bash << EOF
sudo apt install apache2 libapache2-mod-wsgi-py3 python3 python3-pip -y
sudo pip3 install flask
#/home/$username/base/ardupilot/Tools/scripts/configure-ci.sh 
sudo cp /etc/apache2/envvars /etc/apache2/envvars.backup
sudo rm /etc/apache2/envvars
sudo touch /etc/apache2/envvars
cd /home/$username/
git clone https://github.com/ArduPilot/CustomBuild.git
sudo sed 's/www-data/$username/' /etc/apache2/envvars.backup | sudo tee -a /etc/apache2/envvars
sudo echo "export PATH=/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH" | sudo tee -a /etc/apache2/envvars
sudo touch /etc/apache2/sites-available/CustomBuild.conf
sudo echo "<VirtualHost *:80>" | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       ServerName $servername"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       WSGIDaemonProcess app threads=5"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       WSGIScriptAlias / /home/$username/CustomBuild/app.wsgi"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       WSGIScriptAlias /generate /home/$username/CustomBuild/app.wsgi"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       <Directory /home/$username/CustomBuild/>"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       Options FollowSymLinks"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       AllowOverride None"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       Require all granted"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       </Directory>"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       Alias /builds /home/$username/base/builds"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       <Directory /home/$username/base/>"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       Options FollowSymLinks Indexes"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       AllowOverride None"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       Require all granted"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       </Directory>"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       ErrorLog ${APACHE_LOG_DIR}/error.log"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       LogLevel warn"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "       CustomLog ${APACHE_LOG_DIR}/access.log combined"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo echo "</VirtualHost>"  | sudo tee -a /etc/apache2/sites-available/CustomBuild.conf
sudo a2ensite CustomBuild.conf
EOF
 				break;;

        [Nn]* ) break;;
        * ) echo "Please answer Y or N.";;
    esac
done

while true; do
    read -r -p "Do you wish to reboot the system? Required for Custom Build to run(Y/N): " answer
    case $answer in
        [Yy]* ) reboot; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y or N.";;
    esac
done

