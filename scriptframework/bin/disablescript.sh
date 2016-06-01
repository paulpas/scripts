#!/bin/sh
#
# Disables script 
# Paul Pasika
# paul.pasika@proxibid.com
# 11/3/2011
#

. /root/scripts/etc/env

basedir="/root/scripts"

args=1
if [ $# -ne $args ]
then
	echo "Usage: `basename $0` <scriptname>"
	echo
	echo "Available scripts:"
	ls -C1 $basedir/scripts-enabled | egrep -v 'disablescript.sh|enablescript.sh|scripts_sync_to_DFW_ORD.sh'

	exit 1
fi

name=$1
if [ ! -f $basedir/bin/$name ]
then
	echo "Script $name does not exist.  Exiting."
	echo
	echo "Available scripts:"
	ls -C1 $basedir/scripts-enabled | egrep -v 'disablescript.sh|enablescript.sh|scripts_sync_to_DFW_ORD.sh'
	exit 1
fi

# Check if script is neither enabled and disabled
if [ ! -f $basedir/scripts-enabled/$name ] && [ ! -f $basedir/scripts-disabled/$name ]
then
        echo "Script is not found to be enabled and disabled." 
	echo "You need to enable the script first: $basedir/bin/enablescript.sh $name"
        exit 1
fi


# Check if script is already disabled
if [ -f $basedir/scripts-disabled/$name ]
then
	echo "Script $name is already disabled."
	exit 1
fi

# Disable script
mv $basedir/scripts-enabled/$name $basedir/scripts-disabled/

echo "In order to purge the script you must manually delete:"
echo "rm -f $basedir/bin/$name $basedir/scripts-disabled/$name $basedir/scripts-enabled/$name 2>/dev/null"
