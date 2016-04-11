#!/bin/bash
#
#	wangdd 2016/04/07
#
#
#这个脚本用于确定并发的设备,为并发连接查询数据提供设备的类型
#关联脚本monitor.clusterbf.sh 

device_type="total stb smartcard mobile pad pc"
name=`echo "$device_type" | sed 's/ /\n/g'`
COUNT=`echo "$name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$name" | while read LINE; 
		do
    			echo -n '{"{#DEVTYPE}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

