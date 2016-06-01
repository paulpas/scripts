#/bin/bash

echo "Collecting data, stand by..."
echo
for PROCESS in `ps --no-header -eo pid | sed 's/ //g'`; do echo `pmap ${PROCESS} | grep total | sed 's/ total *//'` - `cat /proc/$PROCESS/cmdline 2> /dev/null`; done | sort -rn | more
