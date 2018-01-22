#!/bin/bash

temp=$(mktemp)
echo $temp

######################################################
# Detect unique identifiers to set worker information
######################################################
DetectCPUModel=$(lscpu | grep -w "Model name:" | awk -F: '{print $2}' | sed -e 's/^[ \t]*//;s/ /_/g;s/(R)//g')
DetectComputerModel=$(dmidecode | grep -E 'Product Name' | awk -F: '{print $2}' | sed -e 's/^[ \t]*//;s/ /_/g;s/[[:space:]]*$//' | head -1)
DetectCPUCores="$(getconf _NPROCESSORS_ONLN)x"
echo $DetectCPUWorker
echo $DetectComputerModel
echo $DetectCPUCores
WorkerID="$DetectComputerModel$DetectCPUCores$DetectCPUModel"
echo $WorkerID

#####################################################
# Define miner binaries and configuration files
#####################################################
XMR_CPU_MINER=/usr/local/src/xmr-stak-cpu/bin/xmr-stak-cpu
ConfigSrc=/usr/local/src/xmr-stak-cpu/bin/config.txt.stock
ConfigDest=$temp


################################################################################
# Delete default cpu_threads_conf and replace with detected ideal configuration
################################################################################

sed -e '/"cpu_threads_conf/,+1d' test_null > $ConfigDest
# Append the detected CPU config to the configuration
$XMR_CPU_MINER $ConfigSrc | sed -e '1,/BEGIN/d' -e '/END/,$d'  >> $ConfigDest


