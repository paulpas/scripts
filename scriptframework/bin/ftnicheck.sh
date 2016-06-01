#!/bin/bash
#
# Add to crontab
#* * * * * /root/scripts/scripts-enabled/ftnicheck.sh


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

wget -o /dev/null -O - https://www.ftnirdc.com/httpext.dll?TestDBConnection=4FTNI123X | grep 1 &>/dev/null || echo "FTNI failed" | mailx -s "FTNI failed" paul.pasika@proxibid.com

