#!/bin/bash
while true
do
	echo "Enter keyword and IP seperated by a space [Ex: foo 10.0.0.1]: "
	read word ip
	./password.sh $word $ip
done
