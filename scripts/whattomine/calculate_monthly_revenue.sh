#!/bin/bash
#
# Calculate my personal montly revenue

ETHAddress=2E92eaB40B89367C5cc72b41c3b613197Ecfe591
SCAddress=a477c7fe22964d2c12a934a6e867b9830f6ecd5f4b7937dcfd9f6701a7a34ab3e3816566537f
ZECAddress=t1Rxg7pVjX8UvVZ3bLpNEm1pXpwh9WiTEFg
TimeRangeHours=3

#########################################
# ETH Nanopool
#########################################
function ETHNanoPool
{
# Nanopool ETH ave hash collection. 
# Run until the value isn't null since it's an unreliable API
ETHHashRate=0
while [[ $ETHHashRate == 0 ]]
do
	ETHHashRate=$(curl -s https://api.nanopool.org/v1/eth/avghashratelimited/$ETHAddress/$TimeRangeHours | jq '.data')
done

# Nanopool Revenue calculation, requires ETH ave hash collection.  
# Run until value isn't null since it's an unreliable API
ETHNanopoolRevenue=null
while [[ $ETHNanopoolRevenue == null ]]
do
	ETHNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/eth/approximated_earnings/$ETHHashRate | jq '.data.month.dollars')
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
while [[ $SCHashRate == 0 ]]
do
	SCHashRate=$(curl -s https://api.nanopool.org/v1/sia/avghashratelimited/$SCAddress/$TimeRangeHours | jq '.data')
done

# Nanopool Revenue calculation, requires SC ave hash collection.  
# Run until value isn't null since it's an unreliable API
SCNanopoolRevenue=null
while [[ $SCNanopoolRevenue == null ]]
do
	SCNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/sia/approximated_earnings/$SCHashRate | jq '.data.month.dollars')
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
while [[ $ZECHashRate == 0 ]]
do
	ZECHashRate=$(curl -s https://api.nanopool.org/v1/zec/avghashratelimited/$ZECAddress/$TimeRangeHours | jq '.data')
done

# Nanopool Revenue calculation, requires SC ave hash collection.  
# Run until value isn't null since it's an unreliable API
ZECNanopoolRevenue=null
while [[ $ZECNanopoolRevenue == null ]]
do
	ZECNanopoolRevenue=$(curl -s https://api.nanopool.org/v1/zec/approximated_earnings/$ZECHashRate | jq '.data.month.dollars')
done
echo $ZECNanopoolRevenue
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
for i in $(ETHNanoPool) $(SCNanoPool) $(ZECNanoPool) $(ETHEthermine)
do
	echo "$i"
done | gawk '{sum+=$1} END {print sum}'
