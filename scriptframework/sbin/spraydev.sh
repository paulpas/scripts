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

# Ensure the script runs on $hostallow as root only.
if [[ `whoami` != root ]] || [[ `hostname -s` != $hostallow ]]
then
        echo "$0 needs to be run as root and on the host $targethost."
        echo "Script is being run as `whoami`@`hostname -s`.  Exiting."
        rm -f $pidfile
        exit 1
fi

for i in `cat $ROOTETC/core | grep -v nagios`
do
	# ssh to hosts
	ssh $i

	# Enable remote syslog server on all hosts
	#ssh $i "hostname;sed -i '1i*.* @syslog.proxibid.com' /etc/syslog.conf; /etc/init.d/syslog restart"
	
	# generate ssh-keys if .ssh directory doesn't exist
	#ssh $i "if [ ! -d .ssh ]; then ssh-keygen -t rsa ; fi"

	# install root nagios key to servers
	#ssh $i "echo ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxDRIHCxq4/EkWeIZR9eHhcEP9haYdfNz75WaPReQo2J/AQ6aXc6YoRcuxhiWojp+f752OepPtziRkvcMs+Pg/qkwjxkGzFCd/MWWZbgkvBojmysDDRBE9LJdRc3MOue0tzGnNRZDVOFqThl6GlT4xzpFZNtclGzoowy3nDNpACqvFgGe72Dc//b7cMSqXC6xsGUV0WavRGoAc1KvS680KfL/jIymm7g4kUJk33zEEKp/ZLVSf4ntmstpehvhIJt4cOOfVJdBEtzStMCF8XeIYEAz2uTmgZLqRhlhULFN23tVpMXNZg7bB3F0Rnezsea40yABBc8i3A7/7EcHHIr6FQ== root@nagios.proxibid.com >> .ssh/authorized_keys"

	# validate time / time zone
	#ssh $i "hostname;date"
	
	# sync clocks
	#ssh $i "hostname; /etc/init.d/ntpd stop; ntpdate 192.168.20.8; /etc/init.d/ntpd start; date"

	# remove syslog and install rsyslog and push config files and commit
#	ssh $i "/etc/init.d/syslog stop; yum -y install rsyslog; chkconfig rsyslog on"
#	scp /etc/rsyslog.conf $i:/etc/
#	ssh $i "/etc/init.d/rsyslog restart"
done
