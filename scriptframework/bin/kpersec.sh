#!/bin/bash
while true
do
one=`df -k /data | tail -1 | awk '{print $2}'`
sleep 1
two=`df -k /data | tail -1 | awk '{print $2}'`
rate=$(($two - $one))
mbrate=`echo "$rate /1024" | bc -l`
gbrate=`echo "$mbrate / 1024" | bc -l`
gbpm=`echo "$gbrate * 60" | bc -l`
gbph=`echo "$gbpm * 60" | bc -l`
#mbrate=$(($rate / 1024))
#gbrate=$(($mbrate / 1024))
#gbpm=$(($gbrate * 60))
#gbph=$(($gbpm * 60))
echo
df -h /data
echo "K/sec: $rate"
echo "MB/sec: $mbrate"
#echo "GB/sec: $gbrate"
#echo "GB/min: $gbpm"
echo "average GB/hr: $gbph"
#free
done
