#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9

pro_name=`cat /proc/cpuinfo | grep "processor" | awk '{print $3}'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#CPUCORE}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

