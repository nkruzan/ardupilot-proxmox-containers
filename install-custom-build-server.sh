#!/bin/bash
read -p "Enter username : " username
read -s -p "Enter password : " password
read -r -p "Enter dns name for server:" servername

#we dont want the password to be in the logs...
export HISTIGNORE='*sudo -S*'
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