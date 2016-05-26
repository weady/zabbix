#!/bin/bash
#
#	by wangdd 2016/05/10
#
#这个脚本主要获取需要监控的特殊进程名,用于获取相应的数据
#
#

#----------------------------------------------------------------------
#从zabbix数据库中获取homed,hadoop,crond,apache进程名
function get_process(){
	name=`hostname`
	host="192.168.35.114"
	user="zabbix"
	passwd="zabbixpass"
	mysql_cmd="mysql -u$user -p$passwd -h$host zabbix -e"
	sql="select i.key_ from items i left join hosts h on h.hostid= i.hostid where h.host='"$name"' and h.available=1 and key_ not like '"%#%"' and (key_ like '"hdfs.processstatus%"' or key_ like '"homed.status%"');"
	result=`$mysql_cmd "$sql"`
	process_name=`echo "$result"| grep -v 'key' |sed 's/^\(.*\)h.*\[\(.*\)\].*$/\1\2/g'|awk -F',' '{print $1}'`
}

#----------------------------------------------------------------------
#获取mysql服务的主机分布情况
function get_mysql(){
	local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
	mysql_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u`
	for my_ip in $mysql_ips
	do
		for lo_ip in $local_ips
		do
			if [ "$my_ip" == "$lo_ip" ];then
				mysql_name="mysql"
			fi
		done
	done
}
#----------------------------------------------------------------------
#main
function main(){
	get_process
	get_mysql
	name=`echo "$process_name ssh iptables zabbix_agent $mysql_name"`
}

#----------------------------------------------------------------------
function data_deal(){
	main
	data=`echo "$name" | sed 's/ /\n/g'`
	COUNT=`echo "$data" |wc -l`
	INDEX=0
	echo {'"data"':[
        	echo "$data" | while read LINE; 
                	do
                        	echo -n '{"{#PRONAME}":"'$LINE'"}'
                        	INDEX=`expr $INDEX + 1`
                       		if [ $INDEX -lt $COUNT ]; then
                                	echo ","
                        	fi
                	done
        	echo ]}
}

#----------------------------------------------------------------------
data_deal
