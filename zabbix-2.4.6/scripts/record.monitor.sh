#!/bin/bash
#
#这个脚本是获取录流频道的文件大小，然后让zabbix根据大小是否变化进行判断录流是否正常
#
#
#
#获取频道的中文名
channel="$1"
now_time=`date +%y-%m-%d`
new_time=`date +%Y%m%d`
dbip=`cat /homed/allips.sh | grep "export dtvs_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
user="root"
password=`cat /homed/config_comm.xml | grep "mt_db_pwd" | awk -F'[<>]' '{print $3}'`
function get_channel_name(){
	if [[ "$channel" =~ .*ld$ ]];then
		name=${1%_*}
		sql="set names utf8;select english_name from channel_store where chinese_name='$name'"
		tmp=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
		english=`echo "${tmp}_ld" |grep -v "english_name"`
	else
		sql="set names utf8;select english_name from channel_store where chinese_name='$1'"
		tmp=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
		english=`echo "${tmp}" |grep -v "english_name"`
	fi
}
function check_record(){
	dbip=`cat /homed/allips.sh | grep "export tsg_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
	user="root"
	password="123456"
	sql="set names utf8;select file_name from tsg_total_idx_$1 where file_name like '$new_time%' group by start_idx_time desc limit 1;"
	size_sql="set names utf8;select file_size from tsg_total_idx_$1 where file_name like '$new_time%' group by start_idx_time desc limit 1;"
	tmp=`mysql -B -u$user -p$password -h$dbip homed_tsg -e "$sql"`
	f_size=`mysql -B -u$user -p$password -h$dbip homed_tsg -e "$size_sql"`
	file_name=`echo "$tmp" | grep -v "file_name"`
	f_size=`echo "$f_size" | grep -v "file_size"`
	if [ -z "$file_name" ];then
		echo "0"
	else
		echo "$f_size"
	fi
}
get_channel_name "$channel"
check_record "$english"
