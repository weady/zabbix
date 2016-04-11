#!/bin/bash
#
#
#	wangdd 2016/03/10

name=$1
#获取的系统的硬件信息，操作系统版本
function get_sys_info(){
        system_info=`cat /etc/redhat-release | sed 's/\(.*\) (.*/\1/g'`
        type=`dmidecode | grep -A 4 "System Information"`
        system_type=`echo "$type" | sed 's/\n/ /g'`
        name=`echo "$type" | grep "Manufacturer" | awk '{print $2}'`
        Product=`echo "$type" | grep "Product"|awk -F':' '{print $2}'`
        Serial=`echo "$type" | grep "Serial"|awk -F ':' '{print $2}' | sed 's/ //g'`
        echo $system_info"|"$name $Product"|"$Serial
}


case $name in
	disk_num)
		pro_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		count=`echo "$pro_name" |wc -l`
		echo $count
		;;
	disk_name)
		disk_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		echo $disk_name
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
	ip_list)
		net_ip=`ifconfig |grep  -e 'Link encap' -A1 | grep -v '\-\-' | sed 'N;s/\n//' | awk -F '[[:space:]]*' '{print $1,$7}' | awk -F '[: ]' '{print $1,$NF}' | grep -v 'lo' | awk 'BEGIN{ORS="|"} {print}'`
		echo $net_ip
		;;
	sys_info)
		get_sys_info
		;;
	*)
		echo "Error"
		exit
esac
