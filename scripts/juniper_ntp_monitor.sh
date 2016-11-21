#!/bin/bash
#
# Collect Juniper switch NTP time offset
#
# Paul Pasika
# 11/21/2016
#

temp=`mktemp -d`
yourlogin=read-only-user
ip=10.0.0.1
password="xxxxxxxx"
name=`basename $0 | awk -F. '{print $1}'`

expfile=$temp/$name.exp
logfile=$temp/$name.log
trcfile=$temp/$name.trc
svrfile=$temp/$name.aaa

cat <<EOD > $expfile
#!/usr/bin/expect
spawn /bin/bash

  set prompt "(_>|%|#|\\\\\$) \$"
  catch {set prompt \$env(EXPECT_PROMPT)}


  set timeout 10
  spawn ssh -o stricthostkeychecking=no -l ${yourlogin} ${ip}

  expect "ssword:"
  send "${password}\r"
  set timeout 15
  expect -re \$prompt
  send "show ntp associations| match \\\*\r"
  expect -re \$prompt
  send "exit\r"

  expect -re \$prompt
   exec echo "this script completed on ${host} (${ip})" >> $logfile
  exit

EOD

  # run Expect script
  chmod 700 $expfile
  cat <<EOD >> $trcfile

=========================================================================
=== `date +\%m/\%d/\%y,\%H:\%M:\%S` Connecting to ${host} (${ip})
=========================================================================
EOD
  $expfile | awk '/\*/ {print $9}' | grep [0-9] #>> $trcfile 2>&1

rm -rf $temp
