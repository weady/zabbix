#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9

#pro_name=`df -lh | awk '$1 ~ /dev/ {print $1,$NF}' | awk -F 'dev/' '{print $2}'`
pro_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#DISKNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

