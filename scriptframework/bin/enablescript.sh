#!/bin/sh
#
# Enables script 
# Paul Pasika
# paul.pasika@proxibid.com
# 11/3/2011
#

. ../etc/env

basedir="$ROOT"

args=1
if [ $# -ne $args ]
then
	echo "Usage: `basename $0` <scriptname>"
	echo
	echo "Available scripts:"
	ls -C1 $basedir/bin | egrep -v 'disablescript.sh|enablescript.sh|scripts_sync_to_DFW_ORD.sh'
	exit 1
fi

name=$1
if [ ! -f $basedir/bin/$name ]
then
	echo "Script $name does not exist.  Exiting."
	echo
	echo "Available scripts:"
	ls -C1 $basedir/bin | egrep -v 'disablescript.sh|enablescript.sh|scripts_sync_to_DFW_ORD.sh'
	exit 1
fi

# Check if script is both enabled and disabled
if [ -f $basedir/scripts-enabled/$name ] && [ -f $basedir/scripts-disabled/$name ]
then
	echo "Script is found to be enabled and disabled.  Please remove the symlink for the state desired"
	find $basedir -ls | grep $name
	exit 1
fi

# Check if script is already enabled
if [ -f $basedir/scripts-enabled/$name ]
then
	echo "Script $name is already enabled."
	exit 1
fi

# Enable script

ln -s $basedir/bin/$name $basedir/scripts-enabled/

if [ -f $basedir/scripts-disabled/$name ]
then
	rm -f $basedir/scripts-disabled/$name
fi
