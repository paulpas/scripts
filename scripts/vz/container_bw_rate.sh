#!/bin/bash

DEV=eth0
ctid=$1
ipaddr=$2
bwrate=$3

function valid_container
{
vzlist -H | grep $ctid | grep $ipaddr >/dev/null
valid_status=$?
}

function set_commit
{
valid_container
if (( $valid_status == 0 ))
then
	tc qdisc del dev $DEV root
	tc qdisc add dev $DEV root handle 1: cbq avpkt 1000 bandwidth 100mbit
	tc class add dev $DEV parent 1: classid 1:1 cbq rate ${bwrate}kbit allot 1500 prio 5 bounded isolated
	tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip src $ipaddr flowid 1:1
	tc qdisc add dev $DEV parent 1:1 sfq perturb 10
else
	echo "No container with this CTID and IP exist on this host!"
	vzlist | more
fi
}

set_commit










#function ip_valid
#{
#IP="$ipaddr"
#TEST=`echo "${IP}." | grep -E "([0-9]{1,3}\.){4}"`
#
#if [ "$TEST" ]
#then
#   echo "$IP" | nawk -F. '{
#      if ( (($1>=0) && ($1<=255)) &&
#           (($2>=0) && ($2<=255)) &&
#           (($3>=0) && ($3<=255)) &&
#           (($4>=0) && ($4<=255)) ) {
#         print($0 " is a valid IP address.");
#	ip_valid_status=0
#      } else {
#         print($0 ": IP address out of range!");
#	ip_valid_status=1
#      }
#   }'
#else
#   echo "${IP} is not a valid IP address!"
#	ip_valid_status=1
#fi
#}



