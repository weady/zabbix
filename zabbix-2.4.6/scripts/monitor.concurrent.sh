#!/bin/bash
#
#       by wangdd 2016/04/16
#
#这个脚本是通过ilogslave的run日志获取出本机的并发数
#2016-04-15 00:00:00:773 - [INFO] - PlayCount

argv=$1
device_type=`echo "$argv" | awk -F':' '{print $NF}'`
function get_con_num(){
	path="/homed/ilogslave/log"
	now_time=`date "+%Y-%m-%d %H:%M"`
	tmp=`cat /homed/ilogslave/log/run*.log | grep "${now_time}.*PlayCount.*" | sed 's/^.*\(\<NowTotalCount.*NowDCount 0,\)RequestCount.*\(StbNowTotalCount.*StbNowDCount 0,\).*\(SmartCardNowTotalCount.*SmartCardNowDCount 0,\).*\(MobileNowTotalCount.*MobileNowDCount 0,\).*\(PadNowTotalCount.*PadNowDCount 0,\).*\(PcNowTotalCount.*PcNowDCount 0,\).*/\1\2\3\4\5\6/g' | sed 's/,/\n/g' | sed '/^$/d' |awk '{sum[$1]+=$2}END{for(key in sum) print key,sum[key]}'`
	echo "$tmp" >/tmp/zb_con.log
	result=`cat /tmp/zb_con.log | grep "\<$device_type\>" | awk '{print $2}'`
	echo "$result"
}
get_con_num
