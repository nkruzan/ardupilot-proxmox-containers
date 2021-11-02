#!/bin/bash
cd /home/user/base/ardupilot
source ./modules/esp_idf/export.sh
./waf configure
./waf configure --board=esp32buzz --debug
./waf plane
