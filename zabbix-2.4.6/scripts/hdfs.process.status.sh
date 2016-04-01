#!/bin/bash
#
#这个脚本主要用于检测hadoop进行的状态,hadoop的版本为2.4.6和1.2.1
#
#	by wangdd 2016/04/01

source /etc/profile

process=$1
function process_status(){
	run_process=`jps | grep "$process"`
	if [ -n "$run_process" ];then
		echo $process running
	else
		echo $process stoped
	fi
}

process_status
