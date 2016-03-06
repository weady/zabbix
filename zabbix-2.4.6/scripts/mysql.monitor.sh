#!/bin/bash
#
#This script used to check mysql status
#
#
#	by wangdd 2015/12/9
state="$2"
process="$1"
master_ip=`cat /homed/allips.sh | grep "${process}_mysql_ips=\"[0-9]" | awk -F '"' '{print $2}' | awk '{print $1}'`
slave_ip=`cat /homed/allips.sh | grep "${process}_mysql_ips=\"[0-9]" | awk -F '"' '{print $2}' | awk '{print $2}'`
#
function slave_status(){
	if [ -n "$slave_ip" ];then
		#status=`mysql -B -uroot -p123456 -h${slave_ip} -e "show slave status\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"`
		status=`mysql -B -uroot -p123456 -h${slave_ip} -e "show slave status\G" | grep "$1" | awk -F ':' '{print $NF}' | sed 's/ //g'`
		if [[ "$status" == "Yes" ]];then
			echo "数据库homed_$process的主从复制$state线程的状态是:$status"
		elif [[ "$status" =~ [0-9]* ]];then
			Delay="$status"
		else
			echo "Error:数据库homed_$process的主从复制$state线程的状态为:$status!从库IP是$slave_ip"
		fi
	fi
}
#
case $2 in
	Slave_IO)
		slave_status "Slave_IO_Running"
		;;
	Slave_SQL)
		slave_status "Slave_SQL_Running"
		;;
	Delay)
		slave_status "Seconds_Behind_Master"
		#主从复制延迟大于600秒告警
		if [ "$Delay" -ge 600 ];then
			echo "Waring:主从复制延迟过高，当前延迟值是:$Delay秒!从库IP是$slave_ip"
		else
			echo "数据库homed_$1的主从复制当前延迟值是:$Delay秒"
		fi
		;;
	*)
		echo "Error Input:"
esac
