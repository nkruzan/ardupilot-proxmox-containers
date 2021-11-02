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
	while true; do
		read -r -p "Use ArduPilot repo from github? (Y/N): " answer
		case $answer in
			[Yy]* ) REPO=ArduPilot
					break;;
			[Nn]* ) read -p "Enter github username : " REPO
					while true; do
						read -r -p "Use branch master? (Y/N): " answer
						case $answer in
							[Yy]* ) BRANCH=master
									break;;
							[Nn]* ) read -p "Enter branch name : " BRANCH
									break;;
							* ) echo "Please answer Y or N.";;
						esac
					done
					break;;
			* ) echo "Please answer Y or N.";;
		esac
	done
    #we dont want the password to be in the logs...
    export HISTIGNORE='*sudo -S*'

    #user was successfully added continue here as new user
    echo "$password" | sudo -S -i -u "$username" bash << EOF
sudo apt clean
sudo apt update
sudo apt upgrade -y 
#make sure we clone to correct directory
cd /home/$username/
mkdir base
cd base
git clone -b $BRANCH https://github.com/$REPO/ardupilot.git
cd ardupilot
git submodule update --init --recursive
Tools/environment_install/install-prereqs-ubuntu.sh -y
EOF


fi

while true; do
	read -r -p "Set Up ESP32? (Y/N): " answer
	case $answer in
		[Yy]* ) 
#we dont want the password to be in the logs...
export HISTIGNORE='*sudo -S*'

#user was successfully added continue here as new user
echo "$password" | sudo -S -i -u "$username" bash << EOF
sudo apt-get install git wget flex bison gperf python-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util -y
sudo apt-get install python3 python3-pip python3-setuptools -y
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
sudo pip3 install pexpect empy
cd /home/$username/base/ardupilot
Tools/scripts/esp32_get_idf.sh
cd modules/esp_idf
./install.sh
EOF
				break;;
		[Nn]* ) break;;
		* ) echo "Please answer Y or N.";;
	esac
done




while true; do
    read -r -p "Install Custom Build Server? (Y/N): " answer
    case $answer in
        [Yy]* ) read -r -p "Enter dns name for server:" servername
		while true; do
			read -r -p "Use ArduPilot repo from github? (Y/N): " answer
			case $answer in
				[Yy]* ) REPO=ArduPilot
						break;;
				[Nn]* ) read -p "Enter github username : " REPO
						break;;
				* ) echo "Please answer Y or N.";;
			esac
		done
		echo "$password" | sudo -S -i -u "$username" bash << EOF
#install requirements
sudo apt install apache2 libapache2-mod-wsgi-py3 python3 python3-pip -y
sudo pip3 install flask

#backup apache2 envvars
sudo cp /etc/apache2/envvars /etc/apache2/envvars.backup

#delete envvars
sudo rm /etc/apache2/envvars

#create new envvars file
sudo touch /etc/apache2/envvars

#make sure we clone to correct directory
cd /home/$username/

#clone the repo
git clone https://github.com/$REPO/CustomBuild.git

#populate new envvars file from backup with apache username changed
sudo sed 's/www-data/$username/' /etc/apache2/envvars.backup | sudo tee -a /etc/apache2/envvars

#add toolchain to apache path
sudo echo "export PATH=/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH" | sudo tee -a /etc/apache2/envvars

#create config file for custom build server
#this is modified from base repo, and not using ssl
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

#enable custom build server
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

