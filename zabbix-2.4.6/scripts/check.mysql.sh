#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9
pro_name=`cat /homed/allips.sh | grep "mysql_ips=\"[0-9].*$" | awk -F '[_ ]' '{print $2}'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#SERNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

