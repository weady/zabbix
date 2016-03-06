#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/12/2
#这个脚本的主要作用是获取部署在本机上的homed 服务名，为后面的监控提供监控项目


path="/homed"
cd /homed
source $path/allips.sh
redis_ips_list="$redis_ips"
tsg_ips_list="$tsg_ips"
local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
pro_name_tmp=`grep "^_.*" $path/start.sh | awk -F" " '{print $5}' | awk -F"['.]" '{print $2}' | sed '/^$/d' | sort -u`
function redis_add(){
for ip01 in $redis_ips
do
	for ip02 in $local_ips
	do
		if [ "$ip01" == "$ip02" ];then
			tmp01=`echo "$pro_name_tmp" redis`
		fi
	done
done
}

function tsg_add(){
for ip01 in $tsg_ips
do
	for ip02 in $local_ips
	do
		if [ "$ip01" == "$ip02" ];then
			tmp02=`echo "$pro_name_tmp" tsg`
		fi
	done
done
}
redis_add
tsg_add
[[ -z "$tmp01" ]] && pro_name="$tmp02"
[[ -z "$tmp02" ]] && pro_name="$tmp01"
[[ ! -z "$tmp01"  &&  ! -z "$tmp02" ]] && pro_name=`echo "$tmp02" redis`
[[ -z "$tmp02" && -z "$tmp01" ]] && pro_name="$pro_name_tmp"
pro_name=`echo "$pro_name" | sed 's/ /\n/g'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#HOMEDPRO}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

