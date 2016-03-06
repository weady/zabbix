#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9

list=`top -bn 1 |tail -n +8 | awk '{print $NF}' | sort -u | awk -F'.' '{print $1}'`
pro_name=`echo "$list" | sed 's/ /\n/g'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#HOMEDNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

