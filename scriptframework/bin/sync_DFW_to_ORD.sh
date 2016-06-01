#!/bin/bash
# 
# Rsync /data from imgrzp01 to imgrzp11
#
# Paul Pasika
# paul.pasika@proxibid.com
# 11/3/2011
#
# Add this to crontab to BOTH imgrzp01 and imgrzp11
# * * * * * /root/scripts/sync_DFW_to_ORD.sh
#

. /root/scripts/etc/env


# The side of the house the script runs from DFW or ORD
Site_enabled=DFW

localhostname=`hostname -s`

if [[ $Site_enabled == "DFW" ]]
then
	hostallow="372654-imgrzp01"	# Enable if DFW is the master
	targethost=imgrzp01		#
	destinationhost=imgrzp11	#
elif [[ $Site_enabled == "ORD" ]]
then 
	hostallow="372621-imgrzp11"	# Enable if ORD is the master
	targethost=imgrzp11		#
	destinationhost=imgrzp01	#
fi

# if running on host not local to $Site_enabled
if [[ $localhostname != $hostallow ]] 
then
	exit 1
fi

scriptname=`basename $0`
targetfolder="/data/*"
destinationfolder="/data"
rsyncoptions="--delete -az --inplace"
kbps="--bwlimit=4000"

pid=$$
pidfile=/var/run/`basename $0`.pid

# Only run of there is no other process running.
if [ -f $pidfile ] 
then
	logger -p local0.notice -t $scriptname -i "Exited due to previously running script: `cat $pidfile`."
	exit 1
fi

# Ensure the script runs on imgrzp01 as root only.
if [[ `whoami` != root ]] || [[ `hostname -s` != $hostallow ]]
then
	echo "$0 needs to be run as root and on the host $targethost."
	echo "Script is being run as `whoami`@`hostname -s`.  Exiting."
	rm -f $pidfile
	exit 1
fi

echo $pid > $pidfile

# Sync files
logger -p local0.notice -t $scriptname "Started: $pid."
rsync $rsyncoptions --exclude="/data/images/87/*" $kbps $targetfolder $destinationhost:$destinationfolder
logger -p local0.notice -t $scriptname "Finished: $pid."
rm -f $pidfile
