#!/bin/bash
# Auther: George Beech <george@stackexchange.com>
# 
# This script will auto commit, then push any changes found 
# You need to make sure that your <repo>/.hg/hgrc file has at a minimum the 
# following settings set: 
#
# [ui]
# username = commiter's username
#
# [auth]
# default.username = <username>
# default.password = <account pw>
#
# [paths]
# default = <repo location>
#
############################################################

REPO_ROOT="/srv/tftp/cisco"
LOCK_DIR="/tmp/network_backup/"

if [ `ls ${LOCK_DIR}*.lock | wc -l` -ne 0 ]
then
	exit
fi

while getopts "r:" args do
do
	echo "In GetOPS"
	case "$args" in
		 d) REPO_ROOT="$OPTARG";;
	esac
done

echo $REPO_ROOT

# Make sure we are in the repo
cd $REPO_ROOT

# Check to see if there are incoming changes that we should pull first
hg incoming
# If there are changes pull the latest from the server to make sure we have the lateest
if [ $? -eq 0 ] 
then 
	hg pull --update
	if [ $? -eq 1 ]
	then
		#TODO: Need to send an exception email or use logger?
		logger -p local4.warn -t "[AutoCommiter]" "Unable to pull from repo. Please check the Repo and the config"
		exit 1
	fi
fi

# Check to see if there are any updates that need to be pushed
if [ $(hg status --rev tip -m -a| wc -l) -ne 0 ]
then
	hg commit -m "Auto Commit by commit script. Changes Detected" -A
	hg push
fi