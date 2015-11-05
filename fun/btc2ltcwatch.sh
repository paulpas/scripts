#!/bin/bash
array=( $( for i in btc ltc
do
curl -A Mozilla https://btc-e.com/exchange/"$i"_usd 2>&1| awk '/Last Price/{print $4}' | awk -F\> '{print $2}'
done) )
delta=`echo ${array[0]} - ${array[1]} | bc -l`
percent=`echo ${array[1]} / ${array[0]} | bc -l`
echo ${array[*]} $delta $percent%
