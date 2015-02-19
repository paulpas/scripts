#!/bin/bash
#
# script formats bonnie output and calls gnuplot to create a png graph
# of various bonnie parameters.
#
# feed script bonnie++ output - it will attempt to find the last line of bonnie output
# which is all it really cares about anyway
#
# eg: Using uid:65534, gid:65534.
# Writing a byte at a time...done
# Writing intelligently...done
# Rewriting...done
# Reading a byte at a time...done
# Reading intelligently...done
# start 'em...done...done...done...done...done...
# Create files in sequential order...done.
# Stat files in sequential order...done.
# Delete files in sequential order...done.
# Create files in random order...done.
# Stat files in random order...done.
# Delete files in random order...done.
# Version 1.96 ------Sequential Output------ --Sequential Input- --Random-
# Concurrency 1 -Per Chr- --Block-- -Rewrite- -Per Chr- --Block-- --Seeks--
# Machine Size K/sec %CP K/sec %CP K/sec %CP K/sec %CP K/sec %CP /sec %CP
# bach 32G 2165 93 108640 10 70209 19 5469 97 285324 31 488.6 23
# Latency 14746us 646ms 1855ms 16424us 165ms 90728us
# Version 1.96 ------Sequential Create------ --------Random Create--------
# myhost -Create-- --Read--- -Delete-- -Create-- --Read--- -Delete--
# files /sec %CP /sec %CP /sec %CP /sec %CP /sec %CP /sec %CP
# 16 323 2 +++++ +++ 318 2 353 2 +++++ +++ 246 1
# Latency 226ms 246us 164ms 105ms 61us 325ms
# # 1.96,1.96,myhost,1,1285582173,32G,,2165,93,108640,10,70209,19,5469,97,285324,31,488.6,23,16,,,,,323,2,+++++,+++,318,2,353,2,+++++,+++,246,1,14746us,646ms,1855ms,16424us,165ms,90728us,226ms,246us,164ms,105ms,61us,325ms

error()
{
echo "**Error: $1"
exit
}

# user must enter a filename of saved bonnie output for graphing
test -z "$1" && error "need some bonnie output to graph"
InFile="$1"

# read last line of bonnie output which is all we want to parse anyway
data=`cat "$InFile" | grep -v ^$ | tail -1`
test -z "$data" && error "Unable to find data line in bonnie output."

# some info about bonnie version
ver=`echo "$data" | cut -d',' -f1`
echo "created with bonnie version: $ver"

# hostname of box bonnie was run on
host=`echo "$data" | cut -d',' -f3`
echo "host:$host"

# seq block out k/sec
blockout=`echo "$data" | cut -d',' -f10`

# seq. rewrite output
blockrew=`echo "$data" | cut -d',' -f12`

# seq. block input
blockin=`echo "$data" | cut -d',' -f16`

# seeks are pos 18
seeks=`echo "$data" | cut -d',' -f18`

# seq create is 25
create=`echo "$data" | cut -d',' -f25`

# seq delete is 29
delete=`echo "$data" | cut -d',' -f29`

# seq input create is 31
randcreate=`echo "$data" | cut -d',' -f31`

# random create delete is 35
randdelete=`echo "$data" | cut -d',' -f35`

# if you don't have mktemp (solaris) just set a value for TMPFILE || or if using OSX
#TMPFILE=`mktemp`
TMPFILE=$TMPDIR/filez0
#
echo "0 $blockout" > $TMPFILE
echo "1 $blockrew" >> $TMPFILE
echo "2 $blockin" >> $TMPFILE
echo "3 $seeks" >> $TMPFILE
echo "4 $create" >> $TMPFILE
echo "5 $delete" >> $TMPFILE
echo "6 $randcreate" >> $TMPFILE
echo "7 $randdelete" >> $TMPFILE

# putting all the data on one line causes all the data to plot at one interval
echo "0 $blockout 0.0 0.0 0.0 0.0 0.0 0.0 0.0" > $TMPFILE
echo "1 0.0 $blockrew 0.0 0.0 0.0 0.0 0.0 0.0" >> $TMPFILE
echo "2 0.0 0.0 $blockin 0.0 0.0 0.0 0.0 0.0" >> $TMPFILE
echo "3 0.0 0.0 0.0 $seeks 0.0 0.0 0.0 0.0" >> $TMPFILE
echo "4 0.0 0.0 0.0 0.0 $create 0.0 0.0 0.0" >> $TMPFILE
echo "5 0.0 0.0 0.0 0.0 0.0 $delete 0.0 0.0" >> $TMPFILE
echo "6 0.0 0.0 0.0 0.0 0.0 0.0 $randcreate 0.0" >> $TMPFILE
echo "7 0.0 0.0 0.0 0.0 0.0 0.0 0.0 $randdelete" >> $TMPFILE

# name of png output graph - use data and num secs since 1970 for filename
png="`echo $1 | cut -d'.' -f1`-`date '+%Y-%m-%d.%s'`"".png"

# write tempfile, call gnuplot
gnuplot << EOF
set title "$host graph - bonnie v$ver"
set terminal png truecolor size 800 crop font '/usr/share/fonts/truetype/freefont/FreeMono.ttf, 8'
set output "$png"
set xrange ['-1':'9']
set yrange [0:500000000]
set grid
set xlabel 'operations'
set ylabel 'KB/sec'
set xtics ("blk Out" 0, "blk rew" 1, "blk in" 2, "seeks" 3, "create" 4, "delete" 5, "rnd crt" 6, "rnd del" 7);
set boxwidth .3
plot \
"$TMPFILE" using :1 title "blk out :$blockout" with boxes, \
"$TMPFILE" using :2 title "blk rew :$blockrew" with boxes, \
"$TMPFILE" using :3 title "blk in :$blockin" with boxes, \
"$TMPFILE" using :4 title "seeks :$seeks" with boxes, \
"$TMPFILE" using :5 title "create :$create" with boxes, \
"$TMPFILE" using :6 title "delete :$delete" with boxes, \
"$TMPFILE" using :7 title "rannd crt:$randcreate" with boxes, \
"$TMPFILE" using :8 title "rand del :$randdelete" with boxes
EOF

echo "output saved to $png"
echo "http://localhost/bonnie/default/$png"

# clean up
rm -f $TMPFILE


