#!/bin/bash
#
# Perform multiple actions on a group of servers
# Add your commands and comment out the ones you don't want.
# This will become a messy file
#
# Paul Pasika
# paul.pasika@proxibid.com
# 11/4/2011
#

# ENV
. /root/scripts/etc/env

# The only host this script can run on
hostallow="nagios"

# Ensure the script runs on imgrzp01 as root only.
if [[ `whoami` != root ]] || [[ `hostname -s` != $hostallow ]]
then
        echo "$0 needs to be run as root and on the host $targethost."
        echo "Script is being run as `whoami`@`hostname -s`.  Exiting."
        rm -f $pidfile
        exit 1
fi

for i in `cat $ROOTETC/prodord`
do
	echo $i
	# Enable remote syslog server on all hosts
	#ssh $i "hostname;sed -i '1i*.* @syslog.proxibid.com' /etc/syslog.conf; /etc/init.d/syslog restart"
	
	# install rsyslog on all servers
	#ssh $i "yum -y install rsyslog; chkconfig syslog off; chkconfig rsyslog on"

	# scp rsyslog.conf 
	#scp /etc/rsyslog.conf $i:/etc/

	# ssh to all servers
	#ssh $i 

	# validate time / time zone
	#ssh $i "hostname;date"

	# add compression to rsyslog servers
	#ssh $i "hostname; sed -i 's/*.* @syslog.proxibid.com/*.* @(z9)syslog.proxibid.com/g' /etc/rsyslog.conf ; /etc/init.d/rsyslog reload"

	# list free memory on all servers
	#ssh $i "hostname; free"

	# rsyslog update
	scp /tmp/rsyslog-5.8.6-1.x86_64.rpm $i:/tmp/
	
done
