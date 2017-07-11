#!/usr/bin/env bash

# get profit stats for a coin, 
# prices are for 24 hour average.

# hashrate for Erhash (ETC/ETH) in MH/s
ETHHASHRATE=290
# hashrate for equihash (ZEC) in h/s
EQUIHASH=3900
# hashrate for blake2b (SIA) in Mh/s
SIAHASH=3900

# Total Watts for all rigs
ETHWATTS=2000
EQUWATTS=2000
WATTS=2000 # generic place holder
BLAKEWATTS=0 # 0 because I'm dual mining and it's taking no more power
APIurl="http://whattomine.com/coins.json?utf8=%E2%9C%93&eth=true&factor%5Beth_hr%5D=$ETHHASHRATE.0&factor%5Beth_p%5D=$ETHWATTS.0&factor%5Bgro_hr%5D=71.4&factor%5Bgro_p%5D=$WATTS.0&factor%5Bx11g_hr%5D=8.7&factor%5Bx11g_p%5D=$WATTS.0&factor%5Bcn_hr%5D=1470.0&factor%5Bcn_p%5D=$WATTS.0&eq=true&factor%5Beq_hr%5D=$EQUIHASH.0&factor%5Beq_p%5D=$EQUWATTS.0&factor%5Blrev2_hr%5D=42150.0&factor%5Blrev2_p%5D=$WATTS.0&factor%5Bns_hr%5D=1470.0&factor%5Bns_p%5D=$WATTS.0&factor%5Blbry_hr%5D=180.0&factor%5Blbry_p%5D=$WATTS.0&bk2bf=true&factor%5Bbk2b_hr%5D=$SIAHASH.0&factor%5Bbk2b_p%5D=$BLAKEWATTS.0&factor%5Bbk14_hr%5D=4350.0&factor%5Bbk14_p%5D=$WATTS.0&factor%5Bpas_hr%5D=1740.0&factor%5Bpas_p%5D=$WATTS.0&bkv=true&factor%5Bbkv_hr%5D=7800.0&factor%5Bbkv_p%5D=$WATTS.0&factor%5Bcost%5D=0.14&sort=Profitability7&volume=0&revenue=24h&factor%5Bexchanges%5D%5B%5D=&factor%5Bexchanges%5D%5B%5D=bittrex&factor%5Bexchanges%5D%5B%5D=bleutrade&factor%5Bexchanges%5D%5B%5D=btc_e&factor%5Bexchanges%5D%5B%5D=bter&factor%5Bexchanges%5D%5B%5D=c_cex&factor%5Bexchanges%5D%5B%5D=cryptopia&factor%5Bexchanges%5D%5B%5D=poloniex&factor%5Bexchanges%5D%5B%5D=yobit&dataset=&commit=Calculate&adapt_q_280x=3&adapt_q_380=0&adapt_q_fury=0&adapt_q_470=0&adapt_q_480=0&adapt_q_750Ti=0&adapt_q_10606=0&adapt_q_1070=0&adapt_q_1080=0&adapt_q_1080Ti=0"

temp=`mktemp`

# collect stats for parsing
curl -s "$APIurl" > $temp

echo "Mined USD in 24 hours"
echo "Add SIA to total values because of dual mining factors"
echo

# space delimited
#CurrencyToCheck="ETH ETC ZEC SC"
#
#for i in $CurrencyToCheck

# Filter out NICEHASH because we don't require it.
FILTER="NICEHASH"
jq '.coins[].tag' $temp | sed 's/\"//g' | egrep -v "$FILTER" | while read i
do
     jq ".coins[] | select(.tag == \"$i\") | .tag, .btc_revenue24" $temp | sed 's/\"//g' | sed '$!N;s/\n/ /' > $temp$i
     echo -n "$(awk '{print $1}' $temp$i) "
     echo "$(awk '{print $2}' $temp$i) * $(curl -s http://api.coindesk.com/v1/bpi/currentprice/USD.json | jq .bpi.\"USD\".rate | tr -d \"\"\" | sed -e 's/,//g' )"  | bc -l
done | sort -rnk 2

rm -f $temp*
