#!/bin/bash
#
# Calculate my personal montly revenue

ETHAddress=2E92eaB40B89367C5cc72b41c3b613197Ecfe591
SCAddress=a477c7fe22964d2c12a934a6e867b9830f6ecd5f4b7937dcfd9f6701a7a34ab3e3816566537f
ZECAddress=t1Rxg7pVjX8UvVZ3bLpNEm1pXpwh9WiTEFg
XMRAddress=4JUdGzvrMFDWrUUwY3toJATSeNwjn54LkCnKBPRzDuhzi5vSepHfUckJNxRL2gjkNrSqtCoRUrEDAgRwsQvVCjZbS1MAmG7hKb34Rxh9vp
ETNAddress=etnkJLifFC9aCYsJwwMChXASHLA9kwEVbGVAmpQgB3psc3GCiiXQGfhZfExJyrpGB6hx3Wyqc68tqiNnazapmXCN2BWJ1StKey

TimeRangeHours=3

function timerCount
{
	COUNTER=0
}
function timerBreak
{
	COUNTER=$[$COUNTER +1]
	if [[ $COUNTER == "10" ]]
	then
		break
	fi
}
#########################################
# ETH Nanopool
#########################################
function ETHNanoPool
{
# Nanopool ETH ave hash collection. 
# Run until the value isn't null since it's an unreliable API
ETHHashRate=0
timerCount
while [[ $ETHHashRate == 0 ]]
do
	ETHHashRate=$(curl -s https://api.nanopool.org/v1/eth/avghashratelimited/$ETHAddress/$TimeRangeHours | jq '.data')
	timerBreak
done

# Nanopool Revenue calculation, requires ETH ave hash collection.  
# Run until value isn't null since it's an unreliable API
ETHNanopoolRevenue=null
timerCount
while [[ $ETHNanopoolRevenue == null ]]
do
	ETHNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/eth/approximated_earnings/$ETHHashRate | jq '.data.month.dollars')
	timerBreak
done
echo $ETHNanopoolRevenue
}

#########################################
# SC Nanopool
#########################################
function SCNanoPool
{
# Nanopool SC ave hash collection. 
# Run until the value isn't null since it's an unreliable API
SCHashRate=0
timerCount
while [[ $SCHashRate == 0 ]]
do
	SCHashRate=$(curl -s https://api.nanopool.org/v1/sia/avghashratelimited/$SCAddress/$TimeRangeHours | jq '.data')
	timerBreak
done

# Nanopool Revenue calculation, requires SC ave hash collection.  
# Run until value isn't null since it's an unreliable API
SCNanopoolRevenue=null
timerCount
while [[ $SCNanopoolRevenue == null ]]
do
	SCNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/sia/approximated_earnings/$SCHashRate | jq '.data.month.dollars')
	timerBreak
done
echo $SCNanopoolRevenue
}


#########################################
# ZEC Nanopool
#########################################
function ZECNanoPool
{
# Nanopool SC ave hash collection. 
# Run until the value isn't null since it's an unreliable API
ZECHashRate=0
timerCount
while [[ $ZECHashRate == 0 ]]
do
	ZECHashRate=$(curl -s https://api.nanopool.org/v1/zec/avghashratelimited/$ZECAddress/$TimeRangeHours | jq '.data')
	timerBreak
done

# Nanopool Revenue calculation, requires SC ave hash collection.  
# Run until value isn't null since it's an unreliable API
ZECNanopoolRevenue=null
timerCount
while [[ $ZECNanopoolRevenue == null ]]
do
	ZECNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/zec/approximated_earnings/$ZECHashRate | jq '.data.month.dollars')
	timerBreak
done
echo $ZECNanopoolRevenue
}

#########################################
# XMR Nanopool
#########################################
function XMRNanoPool
{
# Nanopool XMR ave hash collection. 
# Run until the value isn't null since it's an unreliable API
XMRHashRate=0
timerCount
#while (( $COUNTER != 10 ))
#do
while [[ $XMRHashRate == 0 ]]
do
	XMRHashRate=$(curl -s https://api.nanopool.org/v1/xmr/avghashratelimited/$XMRAddress/$TimeRangeHours | jq '.data')
	timerBreak
done

# Nanopool Revenue calculation, requires SC ave hash collection.  
# Run until value isn't null since it's an unreliable API
XMRNanopoolRevenue=null
timerCount
while [[ $XMRNanopoolRevenue == null ]]
do
	XMRNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/xmr/approximated_earnings/$XMRHashRate | jq '.data.month.dollars')
	COUNTER=$[$COUNTER +1]
	timerBreak
done
echo $XMRNanopoolRevenue
}


#########################################
# ETN Nanopool
#########################################
function ETNNanoPool
{
# Nanopool ETN ave hash collection. 
# Run until the value isn't null since it's an unreliable API
ETNHashRate=0
timerCount
while [[ $ETNHashRate == 0 ]]
do
	ETNHashRate=$(curl -s https://api.nanopool.org/v1/etn/avghashratelimited/$ETNAddress/$TimeRangeHours | jq '.data')
	timerBreak
done

# Nanopool Revenue calculation, requires ETN ave hash collection.  
# Run until value isn't null since it's an unreliable API
ETNNanopoolRevenue=null
timerCount
while [[ $ETNNanopoolRevenue == null ]]
do
	ETNNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/etn/approximated_earnings/$ETNHashRate | jq '.data.month.dollars')
	timerBreak
done
echo $ETNNanopoolRevenue
}
#########################################
# ETH Ethermine
#########################################
function ETHEthermine {
ETHPerMinute=$(curl -s https://api.ethermine.org/miner/$ETHAddress/currentStats | jq '.data.usdPerMin')
ETHPerMonth=$(echo "$ETHPerMinute * 43800" | bc -l)
echo $ETHPerMonth
}

SUM=0
for i in $(ETHNanoPool) $(SCNanoPool) $(XMRNanoPool) $(ETNNanoPool) #$(ZECNanoPool) $(XMRNanoPool) # $(ETHEthermine)
do
	echo "$i"
done | gawk '{sum+=$1} END {print sum}'
