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
password=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
user="root"
function get_channel_name(){
	arg=$1
	if [[ "$arg" =~ .*d$ ]];then
		tag=${arg##*_}
		d_name=${arg%_*}
		tmp_name=`echo "$d_name" | grep '_'`
		if [ -z "$tmp_name" ];then
			name=$d_name
		else
			name=`echo "${d_name})"| sed 's/_/(/g'`
		fi
		sql="set names utf8;select english_name from channel_store where chinese_name='"$name"' and status=5 and extra_flag<=128 and extra_flag<>0"
		tmp=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
		english=`echo "${tmp}_${tag}" |grep -v "english_name"`
		stop_channel_sql="set names utf8;select f_record_status from t_record_channel_info where f_record_udp_dir='$english';"
		stop_channel_status=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$stop_channel_sql"`
		record_status=`echo "$stop_channel_status" | grep -v "f_record_status"`
	else
		tmp_name=`echo "$arg" | grep '_'`
		[[ -z "$tmp_name" ]] && name=$arg ||name=`echo "${arg})"| sed 's/_/(/g'`
		sql="set names utf8;select english_name from channel_store where chinese_name='"$name"' and status=5 and extra_flag<=128 and extra_flag<>0"
		tmp=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
		english=`echo "${tmp}" |grep -v "english_name"`
		stop_channel_sql="set names utf8;select f_record_status from t_record_channel_info where f_record_udp_dir='$english';"
		stop_channel_status=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$stop_channel_sql"`
		record_status=`echo "$stop_channel_status" | grep -v "f_record_status"`
	fi
}
function check_record(){
	dbip=`cat /homed/allips.sh | grep "export tsg_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $1}'`
	user="root"
	sql="set names utf8;select file_name from tsg_total_idx_$1 where file_name like '$new_time%' group by start_idx_time desc limit 1;"
	size_sql="set names utf8;select file_size from tsg_total_idx_$1 where file_name like '$new_time%' group by start_idx_time desc limit 1;"
	tmp=`mysql -B -u$user -p$password -h$dbip homed_tsg -e "$sql"`
	f_size=`mysql -B -u$user -p$password -h$dbip homed_tsg -e "$size_sql"`
	file_name=`echo "$tmp" | grep -v "file_name"`
	f_size=`echo "$f_size" | grep -v "file_size"`
	if [ "$record_status" -eq 2 ];then
		echo "$record_status"
	else
		if [ -z "$file_name" ];then
			echo "0"
		else
			echo "$f_size"
		fi
	fi
}
get_channel_name "$channel"
check_record "$english"
