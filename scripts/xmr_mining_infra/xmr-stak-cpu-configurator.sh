#!/bin/bash

temp=$(mktemp)
echo $temp

######################################################
# Detect unique identifiers to set worker information
######################################################
DetectCPUModel=$(lscpu | grep -w "Model name:" | awk -F: '{print $2}' | sed -r 's/^[ \t]*//;s/\(*..\)//g;s/  */_/g')
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


# Disable HT
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
    CPUID=`basename $CPU | cut -b4-`
    echo -en "CPU: $CPUID\t"
    [ -e $CPU/online ] && echo "1" > $CPU/online
    THREAD1=`cat $CPU/topology/thread_siblings_list | cut -f1 -d,`
    if [ $CPUID = $THREAD1 ]; then
        echo "-> enable"
        [ -e $CPU/online ] && echo "1" > $CPU/online
    else
        echo "-> disable"
        echo "1" > $CPU/online
    fi
done
################################################################################
# Delete default cpu_threads_conf and replace with detected ideal configuration
################################################################################

sed -e '/"cpu_threads_conf/,+1d' $ConfigSrc > $ConfigDest
# Append the detected CPU config to the configuration
$XMR_CPU_MINER $ConfigSrc | sed -e '1,/BEGIN/d' -e '/END/,$d'  >> $ConfigDest
sed -i "s/WORKERID/$WorkerID/" $ConfigDest


$XMR_CPU_MINER $ConfigDest

