#!/usr/bin/env bash

# Detect OS, Ubuntu or ethos
# I install Claymore in /opt/Claymore on Ubuntu

if uname -r | grep -- "-generic"
then
        ClaymoreROOT=/opt/Claymore
        ClaymoreRUN=$ClaymoreROOT/start.bash
        RestartCMD="sudo systemctl restart claymore.service"
elif uname -r | grep -- "-ethos"
then
        ClaymoreROOT=$HOME
        ClaymoreRUN=$ClaymoreROOT/claymore.stub.conf
        RestartCMD="minestop; sleep 2; minestart"
fi

# Collect the most profitable coin, currently only ETH and ETC are setup.
BestCoin=`pullstats.jq.sh | grep -E 'ET[CH]' | head -1 | awk '{print $1}' | tr '[:upper:]' '[:lower:]'`

# move config file to the most profitable coin
beforeSUM=`md5sum $ClaymoreRUN | awk '{print $1'}`
afterSUM=`md5sum $ClaymoreRUN.$BestCoin | awk '{print $1}'`

if [[ "$beforeSUM" != "$afterSUM" ]]
then
	cp -f $ClaymoreRUN.$BestCoin $ClaymoreRUN
	
	# restart miner
	echo $RestartCMD | sh
fi

