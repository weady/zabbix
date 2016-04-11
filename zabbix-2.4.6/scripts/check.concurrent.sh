#!/bin/bash
#
#这个脚本主要是统计本机的ilogslave服务号
#
#	wangdd 2016/04/07


ilogslaveid=`cat /homed/start.sh | grep "^_restart.*ilogslave.exe" | awk '{print $(NF-1)}' | tr -d "'"`
COUNT=`echo "$ilogslaveid" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$ilogslaveid" | while read LINE; 
		do
    			echo -n '{"{#SRVID}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

