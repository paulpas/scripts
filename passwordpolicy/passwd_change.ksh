#!/bin/ksh
# Changes Paswords on system
# Uses Expect
# Paul Pasika June 2004
# pimp.m.pasika@mail.sprint.com
#
# -------------------------------------------------------------
# BE SURE TO CHANGE THE KEYWORD ON LINE 84 AND svrfile VARIABLE
# -------------------------------------------------------------
#

COMMON_DIR=/home/dsis/

show_syntax()
{
  cat <<EOD

correct syntax:	./passwd_change.sh

EOD
}

login_proc()
{
  # Build Expect script ..
  # You may need to adjust the timeout accordingly if you expect long delay.
  # 10 second is adequate for most of login response time.
  #password=`echo -e $1 | sed -e 's/\([\[\"]\)/\\\1/g;s/\(\\\\"\\)/\\\1/g'`
#password=$(echo -e $1 | sed -e 's/\\/\\\\\\\\/g;s/\([["]\)/\\\1/g')
password=$(echo -e "$1" | sed -e 's/\\\\/\\\\\\\\\\\\\\\\/g;s/\([["]\)/\\\1/g')

  cat <<EOD > $expfile
#!/usr/bin/expect
spawn /bin/ksh

  set prompt "(%|#|\\\\\$) \$"
  catch {set prompt \$env(EXPECT_PROMPT)}


  set timeout 10
  spawn ssh -o stricthostkeychecking=no -l ${yourlogin} ${ip}

  expect "ssword:"
  send "${youroldpwd}\r"
  set timeout 15 
  expect -re \$prompt
  send "sudo su\r"
  expect "ssword:"
  send "${youroldpwd}\r"
  expect -re \$prompt
  send "passwd root\r"
  expect "assword:"
  send -- "$password\r"
  expect "assword:"
  send -- "$password\r"
  expect -re \$prompt
  send "exit\r"
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
  $expfile >> $trcfile 2>&1
}

main_proc()
{
  while read line; do
    if [ `echo $line|grep -c "^#"` -eq 0 ]; then 
      host=`echo $line|awk '{print $1}'`
      ip=`echo $line|awk '{print $1}'`
      echo
      echo "running on ${host} (${ip})"
      login_proc $(./password.sh ${keyword} ${ip})
    fi
  done < $svrfile 
  echo "\nThis program has completed. Please check the log and trace files \n\n    $logfile \n    $trcfile \n\nto see if any failure. Also please delete following files after checking: \n\n  $logfile, \n  $trcfile \n  $svrfile"
}

interactive_mode()
{
  expfile=$COMMON_DIR/passwd.exp
  logfile=$COMMON_DIR/passwd.log
  trcfile=$COMMON_DIR/passwd.trc
  svrfile=$COMMON_DIR/iplist.aaa
  
  echo "Using $svrfile"
  echo "\n"
  echo "\nEnter your current UNIX login userid: \c"
  read yourlogin
  echo "Enter your current UNIX login password: \c"
  stty -echo	# disable echoing to keep password not shown
  read youroldpwd
  stty echo   # enable echoing again
  echo "\nEnter the keyword: \c"
  read keyword
  stty echo   # enable echoing again






#  rm -f $logfile
   rm -f $trcfile
#  rm -f $svrfile


    main_proc
}

# main program

case $# in
  0)	interactive_mode
	rm -f $expfile
	chmod 700 $trcfile
	if [ -f $logfile ]; then
  	  chmod 700 $logfile
	fi
	exit;;
  *)  	show_syntax
	exit 1;;
esac

