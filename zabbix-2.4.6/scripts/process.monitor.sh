#!/bin/bash
#
#	by wangdd 2016/05/09
#
#这个脚本主要是监控特定进程的内存占用量,内存利用率，CPU利用率
#
#


#!/bin/bash
#
#This script used get someone process memory value from `top`
#
#	wangdd 2015/10/15
#
#
process_name=$1
function mem(){
	p_name=$1
	if [[ "$p_name" =~ mysql|ssh|zabbix_agent ]];then
		p_name="${p_name}d"
	fi
	sum=0
	sum1=0
	file=`top -bn 1 |tail -n +8 | awk '{print $6,$NF}' | grep "$p_name\>"`
	value=`echo "$file" | awk '{print $1}'`
	for val in $value
	do
		if [[ "$val" =~ m$ ]];then
			num=`echo "$val" | sed 's/[a-z]*//g'`
			tmp=`echo "$num*1024" | bc`
			sum=`echo "$sum+$tmp" | bc`
		elif [[ "$val" =~ g$ ]];then
			num=`echo "$val" | sed 's/[a-z]*//g'`
			tmp=`echo "$num*1024*1024" | bc`
			sum=`echo "$sum+$tmp" | bc`
		elif [[ "$val" =~ [0-9]$ ]];then
			num=`echo "$val" | sed 's/[a-z]*//g'`
			tmp=`echo "$num" | bc`
			sum1=`echo "$sum+$tmp" | bc`
		
		fi
	done
	mem_result=`echo "$sum +$sum1" | bc`
	echo $mem_result
}

function cpu(){
	p_name=$1
	if [[ "$p_name" =~ mysql|ssh|zabbix_agent ]];then
		p_name="${p_name}d"
	fi
	sum=0
	file=`top -bn 1 |tail -n +8 | awk '{print $9,$NF}' | grep "$p_name\>"`
	value=`echo "$file" | awk '{print $1}'`
	for val in $value
	do
		sum=`echo "scale=2;$val+$sum" | bc`
	done
echo $sum
	
}

function pmem(){
	p_name=$1
	if [[ "$p_name" =~ mysql|ssh|zabbix_agent ]];then
		p_name="${p_name}d"
	fi
	sum=0
	file=`top -bn 1 |tail -n +8 | awk '{print $10,$NF}' | grep "$p_name\>"`
	value=`echo "$file" | awk '{print $1}'`
	for val in $value
	do
		sum=`echo "scale=2;$val+$sum" | bc`
	done
	if [[ "$sum" =~ ^\.[0-9]* ]];then
		pmem_result=`echo "$sum" | awk -F'.' '{print "0."$NF}'`
	else
		pmem_result=`echo $sum`
	fi
	echo "$pmem_result"
}


function pro_status(){
	process=$1
	if [[ "$process" =~ ssh|mysql|zabbix_agent ]];then
		tmp=`netstat -unltp | grep "${process}d"`
		if [ ! -z "$tmp" ];then
			echo "Running"
		else
			echo "stoped"
		fi
	elif [[ "$process" =~ crond ]];then
		tmp=`ps -ef | grep crond | grep -v grep`
		if [ ! -z "$tmp" ];then
			echo "Running"
		else
			echo "Stoped"
		fi
	elif [[ "$process" =~ iptables ]];then
		tmp=`service iptables status | grep ACCEPT | wc -l`
		if [ "$tmp" -gt 10 ];then
			echo "Running"
		else
			echo "Stoped"
		fi
	elif [[ "$process" =~ httpd ]];then
		tmp=`netstat -unltp | grep "$process"`
		if [ ! -z "$tmp" ];then
			echo "Running"
		else
			echo "stoped"
		fi
	elif [[ "$process" =~ JournalNode|DataNode|DFSZKFailoverController|NameNode ]];then
		tmp=`/usr/java/jdk1.7.0_55/bin/jps | grep "$process"`
        	if [ -n "$tmp" ];then
                	echo "Running"
        	else
                	echo "Stoped"
      		fi
	else
		if [ "$process" == "redis" ];then
                redis_proc=`ps -ef | grep redis | grep -v grep`
                redis_proc_li=`netstat -unltp | egrep "LI.*redis"`
                redis_li_nu=`netstat -unltp | egrep "LI.*redis" | wc -l`
                	if [ ! -z "$redis_proc" ] && [ ! -z "$redis_proc_li" ] && [ "$redis_li_nu" -ge 2 ];then
                        	echo "Running"
                	else
                        	echo "Stoped"
                	fi
        	else
                proc=`ps -ef | grep "$process.*-d" | grep -v grep`
                proc_li=`netstat -unltp | egrep "LI.*$process"`
                proc_li_nu=`netstat -unltp | egrep "LI.*$process" | wc -l`
                	if [ ! -z "$proc" ] && [ ! -z "$proc_li" ] && [ "$proc_li_nu" -ge 2 ];then
                        	echo "Running"
                	else
                        	echo "Stoped"
                	fi
       		fi
	fi
}

#-----------------------------
case $2 in
	mem)
		mem "$process_name"
		;;
	pmem)
		pmem "$process_name"
		;;
	cpu)
		cpu "$process_name"
		;;
	stat)
		pro_status "$process_name"
		;;
	*)
		echo "ERROR"
		;;
esac
