#!/bin/bash
 
#########################################################################
#                                                                       #
#                                                                       #
#                       NATO String converter                           #
#                                                                       #
#               Description: converts string (first parameter given)    #
#               to NATO phonetics-alphabet                              #
#                                                                       #
#               (c) copyright 2008                                      #
#                 by Maniac                                             #
#                                                                       #
#                                                                       #
#########################################################################
#                       License                                         #
#  This program is free software. It comes without any warranty, to     #
#  the extent permitted by applicable law. You can redistribute it      #
#  and/or modify it under the terms of the Do What The Fuck You Want    #
#  To Public License, Version 2, as published by Sam Hocevar. See       #
#  <a href="http://sam.zoy.org/wtfpl/COPYING" title="http://sam.zoy.org/wtfpl/COPYING">http://sam.zoy.org/wtfpl/COPYING</a> for more details.                   #
#########################################################################
 
 
 
if [ ! -z "$1" ] ; then
        LENGTH=${#1}
        COUNTER=0
        until [ "$COUNTER" -ge "$LENGTH" ] ; do
        STR=${1:$COUNTER:1}
        case $STR in
 
                a)      OUTPUT="$OUTPUT - alpha"
                ;;
                A)       OUTPUT="$OUTPUT - ALPHA"
                ;;
                b)      OUTPUT="$OUTPUT - bravo"
                ;;
                B)      OUTPUT="$OUTPUT - BRAVO"
                ;;
                c)      OUTPUT="$OUTPUT - charlie"
                ;;
                C)      OUTPUT="$OUTPUT - CHARLIE"
                ;;
                d)      OUTPUT="$OUTPUT - delta"
                ;;
                D)      OUTPUT="$OUTPUT - DELTA"
                ;;
                e)      OUTPUT="$OUTPUT - echo"
                ;;
                E)      OUTPUT="$OUTPUT - ECHO"
                ;;
                f)      OUTPUT="$OUTPUT - foxtrot"
                ;;
                F)      OUTPUT="$OUTPUT - FOXTROT"
                ;;
                g)      OUTPUT="$OUTPUT - golf"
                ;;
                G)      OUTPUT="$OUTPUT - GOLF"
                ;;
                h)      OUTPUT="$OUTPUT - hotel"
                ;;
                H)      OUTPUT="$OUTPUT - HOTEL"
                ;;
                i)      OUTPUT="$OUTPUT - india"
                ;;
                I)      OUTPUT="$OUTPUT - INDIA"
                ;;
                j)      OUTPUT="$OUTPUT - juliet"
                ;;
                J)      OUTPUT="$OUTPUT - JULIET"
                ;;
                k)      OUTPUT="$OUTPUT - kilo"
                ;;
                K)      OUTPUT="$OUTPUT - KILO"
                ;;
                l)      OUTPUT="$OUTPUT - lima"
                ;;
                L)      OUTPUT="$OUTPUT - LIMA"
                ;;
                m)      OUTPUT="$OUTPUT - mike"
                ;;
                M)      OUTPUT="$OUTPUT - MIKE"
                ;;
                n)      OUTPUT="$OUTPUT - november"
                ;;
                N)      OUTPUT="$OUTPUT - NOVEMBER"
                ;;
                o)      OUTPUT="$OUTPUT - oscar"
                ;;
                O)      OUTPUT="$OUTPUT - OSCAR"
                ;;
                p)      OUTPUT="$OUTPUT - papa"
                ;;
                P)      OUTPUT="$OUTPUT - PAPA"
                ;;
                q)      OUTPUT="$OUTPUT - quebec"
                ;;
                Q)      OUTPUT="$OUTPUT - QUEBEC"
                ;;
                r)      OUTPUT="$OUTPUT - romeo"
                ;;
                R)      OUTPUT="$OUTPUT - ROMEO"
                ;;
                s)      OUTPUT="$OUTPUT - sierra"
                ;;
                S)      OUTPUT="$OUTPUT - SIERRA"
                ;;
                t)      OUTPUT="$OUTPUT - tango"
                ;;
                T)      OUTPUT="$OUTPUT - TANGO"
                ;;
                u)      OUTPUT="$OUTPUT - uniform"
                ;;
                U)      OUTPUT="$OUTPUT - UNIFORM"
                ;;
                v)      OUTPUT="$OUTPUT - victor"
                ;;
                V)      OUTPUT="$OUTPUT - VICTOR"
                ;;
                w)      OUTPUT="$OUTPUT - whiskey"
                ;;
                W)      OUTPUT="$OUTPUT - WHISKEY"
                ;;
                x)      OUTPUT="$OUTPUT - x-ray"
                ;;
                X)      OUTPUT="$OUTPUT - X-RAY"
                ;;
                y)      OUTPUT="$OUTPUT - yankee"
                ;;
                Y)      OUTPUT="$OUTPUT - YANKEE"
                ;;
                z)      OUTPUT="$OUTPUT - zulu"
                ;;
                Z)      OUTPUT="$OUTPUT - ZULU"
                ;;
                1)      OUTPUT="$OUTPUT - One"
                ;;
                2)      OUTPUT="$OUTPUT - Two"
                ;;
                3)      OUTPUT="$OUTPUT - Three"
                ;;
                4)      OUTPUT="$OUTPUT - Four"
                ;;
                5)      OUTPUT="$OUTPUT - Five"
                ;;
                6)      OUTPUT="$OUTPUT - Six"
                ;;
                7)      OUTPUT="$OUTPUT - Seven"
                ;;
                8)      OUTPUT="$OUTPUT - Eight"
                ;;
                9)      OUTPUT="$OUTPUT - Nine"
                ;;
                0)      OUTPUT="$OUTPUT - Zero"
                ;;
                "!")    OUTPUT="$OUTPUT - Exclamation"
                ;;
                "#")    OUTPUT="$OUTPUT - Hash"
                ;;
                "?")    OUTPUT="$OUTPUT - Questionmark"
                ;;
                "&")    OUTPUT="$OUTPUT - Ampersand"
                ;;
                "+")    OUTPUT="$OUTPUT - Plus"
                ;;
                "-")    OUTPUT="$OUTPUT - Dash"
                ;;
                "|")    OUTPUT="$OUTPUT - Pipe"
                ;;
                "$")    OUTPUT="$OUTPUT - Dollar"
                ;;
                "_")    OUTPUT="$OUTPUT - Underscore"
                ;;
                "/")    OUTPUT="$OUTPUT - Slash"
                ;;
                "'\'")  OUTPUT="$OUTPUT - Backslash"
                ;;
                "*")    OUTPUT="$OUTPUT - Asterisk"
                ;;
                "%")    OUTPUT="$OUTPUT - Percent"
                ;;
                "@")    OUTPUT="$OUTPUT - At"
                ;;
                "=")    OUTPUT="$OUTPUT - Equals"
                ;;
                "(")    OUTPUT="$OUTPUT - Left parenthesis"
                ;;
                ")")    OUTPUT="$OUTPUT - Right parenthesis"
                ;;
                "[")    OUTPUT="$OUTPUT - Squared bracket open"
                ;;
                "]")    OUTPUT="$OUTPUT - Squared bracket closed"
                ;;
                "{")    OUTPUT="$OUTPUT - Brace open"
                ;;
                "}")    OUTPUT="$OUTPUT - Brace close"
                ;;
                ".")    OUTPUT="$OUTPUT - Dot"
                ;;
                ",")    OUTPUT="$OUTPUT - Comma"
                ;;
                ";")    OUTPUT="$OUTPUT - Semicolon"
                ;;
                ":")    OUTPUT="$OUTPUT - Colon"
                ;;
                "ü")    OUTPUT="$OUTPUT - übel"
                ;;
                "Ü")    OUTPUT="$OUTPUT - Übel"
                ;;
                "ö")    OUTPUT="$OUTPUT - öse"
                ;;
                "Ö")    OUTPUT="$OUTPUT - Öse"
                ;;
                "ä")    OUTPUT="$OUTPUT - ärger"
                ;;
                "Ä")    OUTPUT="$OUTPUT - Ärger"
                ;;
 
        esac
        let COUNTER+=1
        done
 
 
 
OUTLEN=${#OUTPUT}
echo ${OUTPUT:2:$OUTLEN}
else
echo "$0 [word to show in phoneatics]"
exit
fi

