#!/usr/bin/env bash

# Detect OS, Ubuntu or ethos
# I install Claymore in /opt/Claymore on Ubuntu

# 
if [ -d $HOME/git/scripts/scripts/whattomine ]
then
     BINROOT=$HOME/git/scripts/scripts/whattomine
     PATH=$PATH:$BINROOT
else
     exit 1
fi

if uname -r | grep -- "-generic" >/dev/null
then
        ClaymoreROOT=/opt/Claymore
        ClaymoreRUN=$ClaymoreROOT/start.bash
        RestartCMD="sudo systemctl restart claymore.service"
elif uname -r | grep -- "-ethos" >/dev/null
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

