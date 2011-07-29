#!/bin/bash
# Author: George Beech <george@stackexchange.com>
# Created: 2011-05-11
#
# Purpose: 
# This script is to backup cisco config files. It uses SNMP methods provided by Cisco 
# as of IOS 12.0
#
# Dependancies: 
# 
# Net-SNMP Package
# Needed Cisco MIBS (http://tools.cisco.com/Support/SNMP/do/BrowseOID.do):
# 	CISCO-SMI-V1SMI
# 	SNMPv2-TC-V1SMI
#	CISCO-CONFIG-COPY-MIB-V1SMI
#	CISCO-FLASH-MIB
#####################################################

# Defaults

# We need a random number to assign to the job id. It ages after 5 mins so 3 digits should be fine
RANDOM_ID=$(rand -M 999)

# You can hard code these .. if you want ...
CISCO_DEVICE="1.1.1.1"
TFTP_SERVER="1.1.1.1"

# This is the path from the _root_ of your tftp server
BACKUP_PATH="/"
BACKUP_FILE="backup.cfg"
SNMP_COMMUNITY="private"

#This is set to the location on disk of your tftp directory
REAL_TFTP_DIR="/srv/tftp"
TFTP_USER="nobody"

# Syslog information. Log lever for Success (S_) and fail (F_) as well as the
# Tag to prefix the log entries with.
S_LOG_PRI="local3.info"
F_LOG_PRI="local3.warn"
LOG_TAG="[CISCO-BACKUP]"

function print_help
{
	cat <<HELP
This program will pull your cisco config via SNMP commands. You must be running an IOS device, and it must be at least IOS 12.2

	-d 
		hostname/ip address of the device you want to pull the config from
	-t
		tftp server hostname/ip address (Not LOCALHOST WILL NOT WORK this is 
		sent to the device
	-p
		backup path - this is the path from the ftp server so '/' is the 
		root of the ftp base dir, not your root directory
	-f	
		backup file name - the name you want to save the config as
	-c
		your SNMP RW community (defaults to 'private')
	-h 
		This help
HELP
	exit 1
}

if [ -z $1 ]
then
	print_help
fi

#works best as root - i guess for now just make sure we are root
# in the future i'll figure out the create directory with correct perms stuff
if [ $UID -ne 0 ] 
then 
	echo "Need to be root"
	exit 1
fi

#First we want to parse the command line arts
while getopts "d:t:p:f:c:hv" args
do
	case "$args" in 
		d)	CISCO_DEVICE="$OPTARG";;
		t)	TFTP_SERVER="$OPTARG";;
		p)	BACKUP_PATH="$OPTARG";;
		f)	BACKUP_FILE="$OPTARG";;
		c)	SNMP_COMMUNITY="$OPTARG";;
		h)	print_help;;
		v)	VERBOSITY=1;;
		[?])	print_help;;
	esac
done

if [ -n $VERBOSITY ]
then
	logger -p $S_LOG_PRI -t $LOG_TAG "Device: $CISCO_DEVICE TFTP SERVER: $TFTP_SERVER Path: $BACKUP_PATH File: $BACKUP_FILE Community: $SNMP_COMMUNITY"
	echo "Device: $CISCO_DEVICE"
	echo "TFTP SERVER: $TFTP_SERVER"
	echo "Path: $BACKUP_PATH"
	echo "File: $BACKUP_FILE"
	echo "Community: $SNMP_COMMUNITY"
	
	cat <<COMMAND
# SNMP Set - tells the copy to start
snmpset -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE \
ccCopyProtocol.$RANDOM_ID i tftp \
ccCopySourceFileType.$RANDOM_ID i runningConfig  \
ccCopyDestFileType.$RANDOM_ID i networkFile  \
ccCopyServerAddress.$RANDOM_ID a $TFTP_SERVER  \
ccCopyFileName.$RANDOM_ID s $BACKUP_PATH/$BACKUP_FILE \
ccCopyEntryRowStatus.$RANDOM_ID i active
COMMAND
fi
if [ -n $VERBOSITY ]
then
	logger -p $S_LOG_PRI -t $LOG_TAG ${REAL_TFTP_DIR%/}${BACKUP_PATH%/}
	echo ${REAL_TFTP_DIR%/}${BACKUP_PATH%/}
fi
# Test to make sure the wanted path exists
if [ ! -d ${REAL_TFTP_DIR%/}${BACKUP_PATH%/} ]
then 
	# THIS IS A HACK NEEDS TO BE FIXED FOR REALZ YO
	mkdir -m 777 -p ${REAL_TFTP_DIR%/}${BACKUP_PATH%/}
	if [ ! -d ${REAL_TFTP_DIR%/}${BACKUP_PATH%/} ]
	then
		logger -p $F_LOG_PRI -t $LOG_TAG "Could not create needed directory: ${REAL_TFTP_DIR%/}${BACKUP_PATH%/}"
		echo "Could not create needed directory: ${REAL_TFTP_DIR%/}${BACKUP_PATH%/}"
		exit 1
	fi
	echo ${BACKUP_PATH%/}
fi
logger -p $S_LOG_PRI -t $LOG_TAG "Sending backup command to Device: $CISCO_DEVICE"
# SNMP Set - tells the copy to start
snmpset -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE \
ccCopyProtocol.$RANDOM_ID i tftp \
ccCopySourceFileType.$RANDOM_ID i runningConfig  \
ccCopyDestFileType.$RANDOM_ID i networkFile  \
ccCopyServerAddress.$RANDOM_ID a $TFTP_SERVER  \
ccCopyFileName.$RANDOM_ID s $BACKUP_PATH/$BACKUP_FILE

logger -p $S_LOG_PRI -t $LOG_TAG "Command Sent"

logger -p $S_LOG_PRI -t $LOG_TAG "Sending execute/Activation Command"

# Needs to be a second call, to work properly
snmpset -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE \
ccCopyEntryRowStatus.$RANDOM_ID i active  

logger -p $S_LOG_PRI -t $LOG_TAG "Checking Result"
RESULT=$(snmpwalk -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE ccCopyState.$RANDOM_ID | grep -c "success\|failed")
while [ $RESULT -ne 1 ]
do 
	RESULT=$(snmpwalk -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE ccCopyState.$RANDOM_ID | grep -c "success\|failed")
done
if [ $(snmpwalk -v 2c -c $SNMP_COMMUNITY $CISCO_DEVICE ccCopyState.$RANDOM_ID | grep -c "success") -eq 1 ]
then
	logger -p $S_LOG_PRI -t $LOG_TAG "Backup Successful"
else
	logger -p $F_LOG_PRI -t $LOG_TAG "backup Failed"
fi

echo $RESULT
