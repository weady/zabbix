#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9

name="total available memfree buffers cached pused"
data=`echo "$name" | sed 's/ /\n/g'`
COUNT=`echo "$data" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$data" | while read LINE; 
		do
    			echo -n '{"{#MEMTYPE}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

