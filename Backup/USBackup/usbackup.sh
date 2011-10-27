#!/bin/bash

##############################################################################
# usbackup.sh
#
# by Serge van Ginderachter <serge@vanginderachter.be>
# http://www.vanginderachter.be http://www.ginsys.be
#
# This is a simple shell script to sync two directories, from a local disk to 
# an external (usb) disk. The external disk can be one of many, teh script will 
# check which is online, based on the file systems uuid,  and mount it 
# automagically.
#
# When called without a parameter, the script will execture a default rsync 
# command to sync disks. When called with parameters, the parameters are
# considered as a separate command, and those are executed.
#
# After command execution, the disk is unmounted, and fsck is executed on it.
#
# The default rsync command was crafted to sync a local rsnapshot
# (www.rsnapshot.org) backup repository to an external disk.
#
##############################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

##############################################################################
# internal parameters, don't change
config="usbackup.conf" # should be in /etc or in current dir
count=0
##################################################################

say() {
        MESSAGE="$1"
        TIMESTAMP=$(date +"%F %T")
        if [ "$verbose" != "0" ] ; then echo -e "$TIMESTAMP $MESSAGE_PREFIX $MESSAGE" >&2 ; fi
        logger -t $log_tag -p $log_facility.info "$MESSAGE"
        }

error ()  {
        MESSAGE="$1"
        TIMESTAMP=$(date +"%F %T")
        echo -e $TIMESTAMP $MESSAGE >&2
        logger -t $log_tag -p $log_facility.err "$MESSAGE"
        }

##################################################################
# check for $config in current directory or in /etc/ and source the first one found
if   [ -f $(dirname $0)/$config ]
then source $(dirname $0)/$config
elif [ -f /etc/$config ] 
then source /etc/$config
else error "Please create  $(dirname $0)/$config OR /etc/$config"; exit
fi

# if $verbose is set, also make rsync verbose
if [ $verbose != "0" ] ; then rsync_verbose="-v" ; fi
##################################################################

say "started: $*"

# check for uuid's amongst connected disks
for uuid in $uuids 
	do
		if [ -e /dev/disk/by-uuid/$uuid ]
			then usb=$uuid ; let count=count+1
		fi
	done

# we found 0, 1 or more filesystems
case $count in 
	0)
		error "Error: no defined disk available."
		exit 1
		;;
	1)
		true
		;;
	*)
		#error "Error: more than one disk available."
		#exit 1
		error "Warning: more than one disk available. Continuing with the last one enumerated."
		;;
esac

# $usb holds the uuid of the (last) disk we want to mount
# we check if it is already mounted, and if not, we mount it

say "Mounting disk /dev/disk/by-uuid/$usb = $(readlink -f /dev/disk/by-uuid/$usb)"
if $(grep -q $(readlink -f /dev/disk/by-uuid/$usb) /etc/mtab )
then say "Disk $(readlink -f /dev/disk/by-uuid/$usb) was already mounted."
elif $(mount /dev/disk/by-uuid/$usb $mountpoint)
then say "Disk $(readlink -f /dev/disk/by-uuid/$usb) was mounted."
else error "Disk $(readlink -f /dev/disk/by-uuid/$usb) failed to mount at $(date)." ; exit 1
fi


# checking to execute the default command or a parameter command
if [ "$*" = "" -a ! "$backup_root" = "" ]
        then 	# sync backup_root to usb
	say "executing default command: rsync -aH --delete --numeric-ids --relative $backup_root/ $mountpoint/"
	rsync -aH --delete --numeric-ids --relative $rsync_verbose $backup_root/ $mountpoint/  && say "default command returns success" || error "default command returns error"
	else 	# execute command in parameters
	say "executing parameter command: $*"
	eval $* && say "Command $* -- returns success" || error "Command returns error"
fi

## umount afterwards
if $(umount /dev/disk/by-uuid/$usb)
        then say "Disk $(readlink -f /dev/disk/by-uuid/$usb) was unmounted."
        else error "Unmounting disk failed at $(date)."; exit 1
fi

## fsck usb disk
say "/sbin/e2fsck -p /dev/disk/by-uuid/$usb"
/sbin/e2fsck -p /dev/disk/by-uuid/$usb >/dev/null

## spin down disk (need sg3-utils package)
say "/usr/bin/sg_start --readonly --stop /dev/disk/by-uuid/$usb"
/usr/bin/sg_start --readonly --stop /dev/disk/by-uuid/$usb

