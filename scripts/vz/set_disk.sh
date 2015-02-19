#!/bin/bash

ctid=$1
ipaddr=$2
disk=$3

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
	vzctl set $ctid --diskspace ${disk}G --save
	
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



