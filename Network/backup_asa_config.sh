#!/bin/bash
#CONFIG_PATH="/srv/tftp/cisco/ny-asa"
#ASA_IP="10.7.0.1"
ASA_IP=$1
CONFIG_PATH=$2
LOCK_DIR="/tmp/network_backup/"
LOCK_FILE="${ASA_IP}.lock"

if [ ! -d ${LOCK_DIR} ]
then
	mkdir -p ${LOCK_DIR}
fi

if [ -e ${LOCK_DIR}${LOCK_FILE} ]
then
	exit
else
	touch ${LOCK_DIR}${LOCK_FILE}
	if [ ! -d ${CONFIG_PATH} ]
	then
		mkdir -p ${CONFIG_PATH}
	fi
	/usr/bin/wget --no-check-certificate --http-user=svc_asabackup --http-password=55kEahCRyrpSwXuR8OTY -O ${CONFIG_PATH}/config https://${ASA_IP}/config
	sed -i -e '1d' ${CONFIG_PATH}/config
	sed -i -e '1d' ${CONFIG_PATH}/config
fi

rm ${LOCK_DIR}${LOCK_FILE}
