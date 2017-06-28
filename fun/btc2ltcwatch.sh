#!/bin/bash
array=( $( for i in eth ltc
do
curl -A Mozilla https://btc-e.com/exchange/"$i"_usd 2>&1| awk '/Last: /{print $3}' | awk -F\> '{print $2}'
done) )
delta=`echo ${array[0]} - ${array[1]} | bc -l`
percent=`echo "scale=4; ${array[1]} / ${array[0]} *100" | bc -l`
echo ${array[*]} $delta $percent%
