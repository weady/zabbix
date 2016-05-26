#!/bin/bash
#
#This scripts used to check homed service status
#
#	by wangdd 2015/12/1
#
#这个脚本的作用对本机的homed 服务进行监控，通过进程+监听端口+监听的端口号数量 三个条件判断服务是否正常运行
#


#chmod +s /bin/netstat >/dev/null 2>&1
process="$1"
if [ "$process" == "tsg" ];then
	servid=`cat /homed/tsg/bin/start.sh | grep ".*-d" |awk '{print $3}'`
elif [ "$process" == "db_writer" -o "$process" == "db_router" ];then
	servid=`cat /homed/start.sh | grep "^_restart.*${process}.exe"| sed "s/.*\(-d.*\)/\1/g" | awk -F"'" 'BEGIN{ORS="#"}{print $3,$5}'`
else
	servid=`cat /homed/start.sh | grep "^_restart.*${process}.exe"| sed "s/.*\(-d.*\)/\1/g" | awk -F"'" '{print $3}'`
fi
function process_status(){
	if [ "$process" == "redis" ];then
		redis_proc=`ps -ef | grep redis | grep -v grep`
		redis_proc_li=`netstat -unltp | egrep "LI.*redis"`
		redis_li_nu=`netstat -unltp | egrep "LI.*redis" | wc -l`
        	if [ ! -z "$redis_proc" ] && [ ! -z "$redis_proc_li" ] && [ "$redis_li_nu" -ge 2 ];then
			echo "|---|Redis Running"
        	else
			echo "|---|Redis Stoped"
        	fi
	else
		proc=`ps -ef | grep "$process.*-d" | grep -v grep`
       		proc_li_nu=`netstat -unltp | egrep "LI.*$process" | wc -l`
       		if [ ! -z "$proc" ] && [ "$proc_li_nu" -ge 2 ];then
			echo "|$servid|$process Running"
        	else
			echo "|$servid|$process Stoped"
        	fi
	fi
}
function crond(){
	proc=`ps -ef | grep crond | grep -vE "grep|homed.monitor.sh"`
	if [ -n "$proc" ];then
		echo "crond Running"
	else
		echo "crond Stoped"
	fi
}
function other(){
	proc=`ps -ef | grep "$process" | grep -vE "grep|homed.monitor.sh"`
	netstat_http=`netstat -unlt | grep "\<80\>"`
	if [ -n "$proc" -a -n "$netstat_http" ];then
		echo "Apache Running"
	else
		echo "Apache Stoped"
	fi
}
#
case $2 in
	status)
		if [ "$process" == "crond" ];then
			crond
		elif [ "$process" == "httpd" ];then
			other
		else
			process_status
		fi
		;;
	*)
		echo "Error Input:"
		;;
esac
	
	
