#!/bin/bash

export PATH=/usr/gnu/bin:/usr/bin:/usr/sbin:/sbin
export last_local_snapshot="`zfs list -t snapshot -o name | grep $1 | sort | tail --lines=1`"
export new_local_snapshot=""$1@`date"+%Y-%m-%d %H:%M:%S"`""
export last_remote_snapshot=`ssh root@$2"zfs list -t snapshot -o name | grep $1 " | sort | tail --lines=1`

echo "last previous snapshot: " $last_local_snapshot
echo "new snapshot: " $new_local_snapshot
echo "last remote snapshot: " $last_remote_snapshot

zfs snapshot "$new_local_snapshot"

echo "zfs send -i \"$last_remote_snapshot\" \"$new_local_snapshot\" | ssh root@$2\"zfs receive $1 \""
zfs send -i "$last_remote_snapshot" "$new_local_snapshot" | /usr/local/bin/lzop -1c | ssh root@$2"/usr/local/bin/lzop -dc | zfs receive $1 "

export new_last_remote_snapshot=`ssh root@$2"zfs list -t snapshot -o name | grep $1 " | sort | tail --lines=1`

if [ "$new_local_snapshot" == "$new_last_remote_snapshot" ]; then

echo "$new_local_snapshot replicated to $2 successfully." >> /root/replicate_vms.log
zfs destroy "$last_local_snapshot"
ssh root@$2"zfs destroy \"$last_remote_snapshot\""
else
echo "$new_local_snapshot failed to replicate to $2! ERROR!" >> /root/replicate_vms.log
fi
----------
