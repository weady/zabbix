#!/bin/bash
#
#This script used to get disk monitor information,this information get from /proc/diskstats
#
#read_ops---磁盘读的次数	zabbix{unit:ops/second |Store value: speed per second}
#read_ms--磁盘读的毫秒数	zabbix{unit: ms |Store value: speed per second}
#read_sectors---读扇区次数，一个扇区等于512B	zabbix{unit: B/sec|Store value: speed per second}
#write_ops---磁盘读的次数	zabbix{unit:ops/second |Store value: speed per second}
#write_ms--磁盘读的毫秒数	zabbix{unit: ms |Store value: speed per second}
#write_sectors---读扇区次数，一个扇区等于512B	zabbix{unit: B/sec|Store value: speed per second}
#io_ms---花费在IO操作上的毫秒数 zabbix{unit:ms | Store value: speed per second}
#

disk=$1
time_y=`date "+%Y-%m-%d %T"`
time_d=`date +%d | tr -d '0'`
time_h=`date +%H:%M`
#--------------------------
function disk_status_check(){
	par_num=`df -lh | grep $disk|wc -l`
	mount_point=`df -lh | grep $disk|awk '{print $NF}'`
	if [ $par_num -gt 1 ];then
		echo "$time_y" >/tmp/zb_disk_check.txt
		if [ $? -eq 1 ];then
			echo "ERROR:系统盘无法写入数据"
		else
			echo "OK"
		fi
	elif [ $par_num -eq 1 ];then
		echo "$time_y" >$mount_point/zb_disk_check.txt
		 if [ $? -eq 1 ];then
                        echo "ERROR:$disk [$mount_point] 无法写入数据"
                else
                        echo "[$mount_point] OK"
		fi
	fi
}
function bad_block(){
	result=`cat /var/log/messages | grep "${time_d} ${time_h}.*${disk}.*Hardware Error" | tail -n 3`
	if [ ! -z $result ];then
		echo "ERROR:$disk 有坏块"
	else
		echo "OK"
	fi
}


case $2 in
	read_ops)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $4}'`"
		;;
	read_ms)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $7}'`"
		;;
	read_sectors)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $6}'`"
		;;
	write_ops)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $8}'`"
		;;
	write_ms)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $11}'`"
		;;
	write_sectors)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $10}'`"
		;;
	io_active)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $12}'`"
		;;
	io_ms)
		echo "`grep "$disk\>" /proc/diskstats | awk '{print $13}'`"
		;;
	disk_status)
		disk_status_check		
		;;
	disk_block)
		bad_block		
		;;
	util)
		list=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		count=`echo "$list" | wc -l`
		n=`expr $count + 1`
		num=`iostat -d -x -k 1 3 | tail -n $n | grep "$disk" | awk '{print $NF}'`
		echo $num
		;;
	*)
		echo "Error input:"
		;;
esac
exit 0
