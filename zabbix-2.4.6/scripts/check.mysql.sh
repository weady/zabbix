#!/bin/bash
#
#	wangdd 2015/10/9
#
#这个脚本主要是获取集群中mysql的分布情况，用于检测主从的状态:
#

function get_database(){
	local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
	mysql_slave_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u | awk '{print $2}'`
	for l_ip in $local_ips
	do
		for s_ip in $mysql_slave_ips
		do
			if [ "$l_ip" == "$s_ip" ];then
				pro_name=`cat /homed/allips.sh | grep "mysql_ips=\"[0-9].*$" | grep "$s_ip"|awk -F '[_ ]' '{print $2}'`
			fi
		done
	done
}

function deal_data(){
	get_database
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
}

deal_data
