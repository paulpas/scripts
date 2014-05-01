#!/bin/bash
# Parses exim logs for a subject.  Subject logging must be enabled.
#
# Paul Pasika
# 5/1/2014
# paulpas@petabit.net

scriptname=`basename $0`

function usage {
	echo "Use: ./$scriptname <username|email address>"
	exit 1
} 


if (( $# != 1 ))
then
	usage
fi


grep $1 /var/log/exim_*log | grep "T=\"" | awk '{print $4}' | sort -u | while read i
do
	echo -n "$i => "
	grep $i /var/log/exim_*log | awk -F"T=" '/T=\"/ {print $2}'
done
