#!/bin/bash
#CONFIG_PATH="/srv/tftp/cisco/ny-asa"
#ASA_IP="10.7.0.1"
ASA_IP=$1
CONFIG_PATH=$2

if [ ! -d ${CONFIG_PATH} ]
then
	mkdir -p ${CONFIG_PATH}
fi
/usr/bin/wget --no-check-certificate --http-user=<asa_user> --http-password=<asa_password> -O ${CONFIG_PATH}/config https://${ASA_IP}/config
sed -i -e '1d' ${CONFIG_PATH}/config
sed -i -e '1d' ${CONFIG_PATH}/config
