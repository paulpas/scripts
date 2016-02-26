#!/bin/bash
# 
# This script builds another one-liner to look in the contents of a list of files to look for lines that match.
#
# Author: Paul Pasika
# EMail: paulpas@petabit.net
# Date 02/26/2016
#

declare -a files=(`ls --color=auto *.audit`)
#declare -a files=(`ls --color=auto web*.audit`)
#declare -a files=(`ls --color=auto batch*.audit`)

for (( i = 0; i < ${#files[*]}; ++ i ))
do
        # if we're on the last element, exit
        if (( $i == $((${#files[@]}-1)) ))
        then
                exit
        fi
        # if we're on the first element then echo the beginning statement for the rest to run properly
        if (( $i == 0 ))
        then
                echo -n "cat ${files[$i]} | comm -12 - ${files[$i+1]} "
        else
                # Generate the rest of the command 
                echo -n "| comm -12 - ${files[$i+1]} "
        fi
done | sh # remove the "| sh" if you would like to see the command to be executed.
