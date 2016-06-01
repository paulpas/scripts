#!/bin/bash
# Paul Pasika
# paul.pasika@proxibid.com
# 09/16/2011
#
# Monitors directories and rsync's them to the file share for common access.
#
### Configuration
###
###
###
targethost=imgrzp01
LOG="/var/log/ftpfilemon"
PID="/var/run/ftpfilemon.sh.pid"
###
###
###

echo $$ > $PID
ps -ef | grep "bash" | grep "ftpfilemon" | grep -v `cat $PID` | awk '{print "kill "$2}' | sh
killall inotifywait
trap 'killall inotifywait' INT TERM EXIT
trap 'killall -g ftpfilemon.sh' INT TERM EXIT

function reset_counter
{
	if (( $count > 20 ))
	then
		count=0
	fi
}
	for i in EmailImages MarketingImages FTPImages
	do
		inotifywait -m -r --format '%w' /home/$i/ 2>/dev/null | while read j
		do
			echo $$ >> $PID
			size=`du -s /home/$i | awk '{print $1}'`
			while true
			do
				sleep .5
				newsize=`du -s /home/$i | awk '{print $1}'`
				if (( $size != $newsize))
				then
					size=$newsize
					count=0
				elif (( $size == $newsize))
				then
					((count++))
					reset_counter
					if (( $count == 20 )) && (( $size != 20 )) 
					then
						count=0
						date >> $LOG
						rsync --delete --stats -avz /home/$i $targethost:/data/ &>> $LOG
						echo "`date` End of Transfer." >> $LOG
						ssh root@$targethost "chown -R smbguest.smbguest -- /data/$i"
						echo "`date` End of permission modifications." >> $LOG
						#rm -rf /home/$i/* && echo "`date` Removed files in /home/$i/*" >> $LOG 
						continue 2 
					fi
				fi
			done
		done &
	done

	wait
