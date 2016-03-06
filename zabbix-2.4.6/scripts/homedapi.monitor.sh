#!/bin/bash
#
#这个脚本用于检测homed各服务的api是否可以使用,利用curl返回的时间小于0.5秒和返回的信息是否有ok字符去判定API是否正常
#返回的时间为了便于计算都乘了1000,如果小于50(0.6s)说明api返回超时
#
# 	by wangdd 2015/12/16
#
#
#ports="11160 11190 11290 11390 11490 11690 11790 11890 11990 12390 12490 12690 12790 12890 12990 13150 13160 13190 13390 13590 17090"

function api_check(){
	path="/homed/$1/config"
	port=`cat $path/config.xml | grep local_port | sort -u | sed 's/.*>\(.*\)<.*$/\1/'|head -n 1`
	url="http://127.0.0.1:$port/monitorqueryprocessstatus"
	Time=`curl -o /dev/null -s -w %{time_total}"\n" "$url"`
	tmp=`echo "$Time*1000" | bc`
	int=`echo "$tmp" | awk '{printf "%d\n",$0}'`
	var=`curl -s $url|grep ok`
	result=`echo "$var" | grep ok`
	if [ -n "$result" ];then
		echo "${Time}"
	else
		echo "0"
	fi
}
if [[ ! "$1" =~ redis|db_* ]];then
	api_check "$1"
fi
