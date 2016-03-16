#!/bin/bash
#
#
#	wangdd 2016/03/10

name=$1

case $name in
	disk_num)
		pro_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		count=`echo "$pro_name" |wc -l`
		echo $count
		;;
	cpu_type)
		core_num=`cat /proc/cpuinfo | grep "name" | wc -l`
		type=`cat /proc/cpuinfo | grep "name" | awk '{print $4,$5,$7,$NF }' | head -n 1`
		echo "$type $core_num 核"
		;;
	cpu_top5)
		name=`top -b n 1 | tail -n +8 | awk '{s[$NF]+=$9} END{for(key in s) print s[key],key}' | sort -nrk 1 | head -n 5 | awk -F '.' 'BEGIN{ORS="|"}{print $1"."$2}'`
                echo $name
		;;
	mem_top5)
		name=`top -b n 1 | tail -n +8 | awk '{s[$NF]+=$10} END{for(key in s) print s[key],key}' | sort -nrk 1 | head -n 5 | awk -F '.' 'BEGIN{ORS="|"}{print $1"."$2}'`
                echo $name
		;;
	*)
		echo "Error"
		exit
esac
