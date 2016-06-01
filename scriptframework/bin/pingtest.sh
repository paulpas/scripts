#!/bin/bash
# 
# Run pings on all local datacenter Linux hosts and alert if times are above threshold
#
# Paul Pasika
# paul.pasika@proxibid.com
# 12/07/2011
#
# Put into Cron:
# */5 * * * * /root/scripts/sbin/pingtest.sh >/dev/null

# Env
. ../etc/env

# The only host and user this script can run on
hostallow="amagi"
userallow="root"

host_user_check

# Config
maxtime=25000 #in microseconds (miliseconds * 1000)
pingcount=5 # sample size
tmp=`mktemp`

echo "Please wait to collect ping times..."
echo
# DFW Check
set -- `cat $ROOTETC/core` 
for a; do
    shift
    for b; do
	pingtime=`echo "ssh $a \"ping -c $pingcount -q $b\"" | sh | awk -F/ '{print $5}' | tail -1`
	if [[ $a = weba01 ]] || [[ $a = weba02 ]] || [[ $a = weba11 ]] || [[ $a = weba12 ]]
	then
        	echo -e "$a \t\t -->\t $b:\t$pingtime ms"
	else
        	echo -e "$a \t -->\t $b:\t$pingtime ms"
	fi
	ping2time=`echo "$pingtime * 1000" | bc | awk -F. '{print $1}'` # convert to milliseconds.  scale=0; didn't work
	if (( $ping2time >= $maxtime ))
	then
		echo -e "$a -->\t $b:\t$pingtime" >> $tmp
	fi
    done &
done | sort &

## ORD Check
#set -- `cat $ROOTETC/prodord` 
#for a; do
#    shift
#    for b; do
#	pingtime=`echo "ssh $a \"ping -c $pingcount -q $b\"" | sh | awk -F/ '{print $5}' | tail -1`
#	if [[ $a = weba01 ]] || [[ $a = weba02 ]] || [[ $a = weba11 ]] || [[ $a = weba12 ]]
#	then
#        	echo -e "$a \t\t -->\t $b:\t$pingtime ms"
#	else
#        	echo -e "$a \t -->\t $b:\t$pingtime ms"
#	fi
#	ping2time=`echo "$pingtime * 1000" | bc | awk -F. '{print $1}'` # convert to milliseconds.  scale=0; didn't work
#	if (( $ping2time >= $maxtime ))
#	then
#		echo -e "$a -->\t $b:\t$pingtime" >> $tmp
#	fi
#    done &
#done | sort &
#wait 
# Send Alert if any alerts are needed
if [ -s $tmp ] 
then
	cat $tmp | mail -s "** Problem Ping Alert" sysadmin@citizensrx.com
fi

# Clean up temp
rm -f $tmp
