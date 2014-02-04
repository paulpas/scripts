#!/bin/bash
# Collect SSL cert information
#1) See if they're hosted on us or someone else by checking:
# i)	SOA of FQDN (foo.bar.com or foo.com)
#     a) using ns1-2.safewebservics.com
#     b) using ns1-2.nmi.com
#     c) ns1-2.networkmerchants.com
#
# ii) SOA IP from #i (foo.bar.com or foo.com)
#	a) SOA records NOT ns1-2.(nmi|networkmerchants).com that ARE IP 216.35.170.17|216.35.170.18
#
# iii)	NS from #i (foo.bar.com or foo.com)
#     a) using ns1-4.p25.dynsect.net
#     b) using ns1-2.safewebservics.com
#     c) using ns1-2.nmi.com
#     d) ns1-2.networkmerchants.com
#
# iv)	NS IPs
#     2) NS records NOT ns1-2.(nmi|networkmerchants).com that ARE IP 216.35.170.17|216.35.170.18
#
# v)	Registraur of foo.com domain
#     a) ENUM + SOA + NS check to see if we have control
#
# CSV KEY:  SSL Cert, SOA, NMI Control (Y|N), NS Control (Y|N), Registrar Control (Y|N) 
# collect domain SOA


echo "SSL Cert, Registrar, NMI Sub-domain SOA, NMI SOA Control, NMI NS Control, NMI Registrar Control, DYNECT Hosted" 

cat branded_customer.lst | while read i
#cat temp_branded | while read i
#cat test.file | while read i
do
	# echo SSL Cert name
        echo -n "$i,"
	# get foo.com domain for later use
	if (( `echo $i | awk -F. '{print NF}'` == 3 ))
	then
		DOMAIN=`echo $i | awk -F. '{print $2"."$3}'`
	elif (( `echo $i | awk -F. '{print NF}'` == 2 ))
	then
		DOMAIN=$i
	fi
        # Get SOA
        SOA=`dig @8.8.8.8 $i SOA | grep -v \;| awk '/SOA/ {print $5}'`
	# echo SOA
        #echo -n "$SOA,"
        # Get SOA IP
        SOAIP=`dig @8.8.8.8 $SOA A | grep -v \;| awk '/A/ {print $5}'`
        #echo "SOAIP $SOAIP"

	# is SOAIP our IP?
	ownSOAIP=`echo $SOAIP | egrep '216.35.170.17|216.35.170.18' &>/dev/null`
	ownSOAIPstatus=`echo $?`
	if (( $ownSOAIPstatus == 0 ))
	then
		NMIcontrol=Y
	else
		NMIcontrol=N
	fi 
        # Get NS for full fqdn
        NS=`dig @8.8.8.8 $i NS | grep -v \;| awk '/NS/ {print $5}'`
        #echo "NS $NS"
		
        # Were there any results?
        NSExist=`echo $NS | wc | awk '{print $2}'`
	ownSubdomain=Y
        #echo "NSExist $NSExist"
        if (( $NSExist == 0 )) # if there are 0 words, then there wasn't an NS record
        then
                #echo "DOMAIN $DOMAIN"
                NS=`dig @8.8.8.8 $DOMAIN NS | grep -v \;| awk '/NS/ {print $5}'`
		ownSubdomain=N
        fi

        # Get NS IP
        OLDIFS=$IFS
        IFS=$'\n'
        for j in $NS
        do
		# echo NS records
		#echo -n "$j,"
		# are they hosted on dynect?
		echo $j | grep -ci dynect.net &>/dev/null
		DYNECTStatus=$?
		if (( $DYNECTStatus == 0 ))
		then
			DYNECTHosted=Y
		else
			DYNECTHosted=N
		fi
                NSIP=`dig @8.8.8.8 $j A | grep -v \;| awk '/A/ {print $5}'`
		# echo NS IPs
                #echo -n "$NSIP,"
		# is NSIP our IP?
		ownNSIP=`echo $NSIP | egrep '216.35.170.17|216.35.170.18' &>/dev/null`
		ownNSIPstatus=`echo $?`
		if (( $ownNSIPstatus == 0 ))
		then
			NSIPcontrol=Y
		else
			NSIPcontrol=N
		fi 
        done
        IFS=$OLDIFS
	
	# Find Registrar
	REGISTRAR=`whois -h whois.crsnic.net $DOMAIN | grep -wi "Registrar:" | awk -F: '{print $2}' | sed -e 's/,//g;s/^[ \t]*//g'`
	#echo Registrar $REGISTRAR
	# echo REGISTRAR
	echo -n "$REGISTRAR,"
		# is REGISTRAR run by us at ENUM?
		ownREGISTRAR=`echo $REGISTRAR | egrep 'ENOM' &>/dev/null`
		ownREGISTRARstatus=`echo $?`
		if (( $ownREGISTRARstatus == 0 ))
		then
			REGISTRARcontrol=Y
		else
			REGISTRARcontrol=N
		fi 
        echo "$ownSubdomain,$NMIcontrol,$NSIPcontrol,$REGISTRARcontrol,$DYNECTHosted"
done
