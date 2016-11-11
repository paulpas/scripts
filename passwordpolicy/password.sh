#!/bin/bash
# Generate root passwords based off of crypted values
#
# Author: Paul Pasika
# Date: 04.08.2008
# email paulpas@petabit.net
# 
# Paypal any donations to paulpas@petabit.net to keep this going.
#
#

if [[ $# -ne 2 ]]
then
                echo "Usage: password.sh <keyword> <IP/Hostname>"
                echo "Example:  ./password.sh foo 10.0.0.1"
                exit 0
fi

# 8 character passwords
#key=`echo $1$2 | /usr/bin/sha256sum  | tr [a-z] [A-Z] | sed -e 's-.-& -2;s-.-& -5;s-.-& -8;s-.-& -11;s-.-& -14;s-.-& -17;s-.-& -20;s-.-& -23' | awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8}'`
# 16 character passwords
key=`echo $1$2 | /usr/bin/shasum  | tr [a-z] [A-Z] | sed -e 's-.-& -2;s-.-& -5;s-.-& -8;s-.-& -11;s-.-& -14;s-.-& -17;s-.-& -20;s-.-& -23;s-.-& -26;s-.-& -29;s-.-& -32;s-.-& -35;s-.-& -38;s-.-& -41;s-.-& -34' | awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13" "$14" "$15" "$16}'`
# 8 character passwords
#key=`echo $1$2 | sha2 -512 -q | tr [a-z] [A-Z] | sed -e 's-.-& -2;s-.-& -5;s-.-& -8;s-.-& -11;s-.-& -14;s-.-& -17;s-.-& -20;s-.-& -23' | awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8}'`

for i in $key
do

string=`(echo ibase=16; echo $i%7E) | bc`
			if (( $string <= 40 ))
			then
				(( string = string + 41 )) # make sure it's a printable character and not a control character
			fi
			if (( $string == 92 ))
			then
				(( string = string + 1 )) # make sure it's a printable character and not a control character
			fi
			#if (( $string == 91 ))
			#then
			#	string="\$string" # make sure it's a printable character and not a control character
			#fi
char=`echo $string | awk '{printf("%c",$0)}'`
#/usr/bin/perl -ew "print ,$char\n";
echo -ne "$char"
done
echo
