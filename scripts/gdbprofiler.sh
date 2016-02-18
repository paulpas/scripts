#!/bin/bash
# Profile a proccess for debugging an issue
# Usage:
# ./gdbprofiler.sh <process name>
#
# Ex: ./gdbprofiler.sh named
#
# Paul Pasika
# paulpas@petabit.net
# 2/18/2016
#
# Original Author http://poormansprofiler.org/
#
#
nsamples=1
sleeptime=0
process=$1
pid=$(pidof $process)

for x in $(seq 1 $nsamples)
  do
    gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $pid
    sleep $sleeptime
  done | \
awk '
  BEGIN { s = ""; } 
  /^Thread/ { print s; s = ""; } 
  /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } 
  END { print s }' | \
sort | uniq -c | sort -r -n -k 1,1
