#!/bin/bash
#
#This script used to get memory information from /proc/meminfo
#
#	wangdd 2015/10/14
#
#内存计算方法:
#MemTotal值作为总内存
#可用内存计算方式：如果Cached值大于MemTotal值则空闲内存为MemFree值，否则空闲内存为MemFree值+Buffers值+Cached值
#
#
#
#
function mem(){
		total=`grep  "MemTotal" /proc/meminfo | awk '{print $2}'`
                memfree=`grep "MemFree" /proc/meminfo | awk '{print $2}'`
                buffers=`grep "Buffers" /proc/meminfo | awk '{print $2}'`
                cached=`grep "\<Cached:" /proc/meminfo | awk '{print $2}'`
		if [ "$1" = "available" ];then
                	if [ "$cached" -gt "$total" ];then
                        	echo $memfree
                	else
                        	free=`echo "scale=4;($memfree+$buffers+$cached)/1024" | bc`
                        	printf "%.3f\n" $free
                	fi
		elif [ "$1" = "pused" ];then
			pused=`echo "scale=4;100*($total-($memfree+$buffers+$cached))/$total" | bc`
                        printf "%.2f\n" $pused
		fi 
}
##

case $1 in
	total)
		echo `grep  "MemTotal" /proc/meminfo | awk '{print $2/1024}'`
		;;
	available)
		mem "available"
		;;
	pused)
		mem "pused"
		;;
	memfree)
                echo `grep "MemFree" /proc/meminfo | awk '{print $2/1024}'`
		;;
	buffers)
                echo `grep "Buffers" /proc/meminfo | awk '{print $2/1024}'`
		;;
	cached)
                echo `grep "\<Cached:" /proc/meminfo | awk '{print $2/1024}'`
		;;
	*)
		echo "Error input:"
		;;
esac
exit 0
