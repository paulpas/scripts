#!/bin/bash
#
# Sync scripts to all hosts in production
#
# Paul Pasika
# paul.pasika@proxibid.com
# 11/3/2011
#
# Add to crontab
# 0 * * * * /root/scripts/scripts-enabled/sync_DFW_to_ORD.sh
#

. /root/scripts/etc/env


hosts="imgrzp01 imgrzp11 webapp01 webapp11 webapp02 webapp12 weba01 weba02"

if [[ `whoami` != root ]] || [[ `hostname -s` != "nagios" ]]
then
        echo "$0 needs to be run as root and on the host $targethost."
        exit 1
fi

for i in $hosts
do
	rsync -az --delete /root/scripts $i:
done
