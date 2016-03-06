#!/bin/bash
#
#这个脚本是获取录流的频道信息，为后面的监控提供监控的录流频道
#
#	wangdd 2015/12/28

#通过homed_dtvs中的channel_store表，过滤出处于上架状态的频道信息，过滤的依据是statu=5 and extra_flag<=128 and extra_flag<>0
#extra_flag标识位，按位存储数据，从低位起：编辑；回看；时移；新增；删除；IP直播；公有属性（留作终端标记）；隐藏
#

passwd=`cat /homed/config_comm.xml | grep "mt_db_pwd" | awk -F'[<>]' '{print $3}'`
#从数据库获取频道信息
function db(){
	dbip=`cat /homed/allips.sh | grep "export $1_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
	user="root"
	password=$passwd
	cmd=`mysql -B -u$user -p$password -h$dbip homed_$1 -e "$2"`
}
#从dtvs的t_record_channel_info表中取出启用录流状态的频道信息
function chennel_select(){
	ch_mysql="set names utf8;select f_record_udp_dir,f_work_flag from t_record_channel_info"
	db "dtvs" "$ch_mysql"
	ch_name_ld=`echo "$cmd" | grep -vE "f_record_udp_dir|f_work_flag" |awk 's=0;s=and($NF,4);{if(s==4) print}' | sort -u|awk '{print $1}' | grep "_ld"`
	for ld_channel in $ch_name_ld
	do
		tmp=${ld_channel%_*}
		ch_name+=`echo "$tmp "`
	done
	ch_ld_name=`echo "$ch_name" | sed 's/ /\n/g' | sed '/^$/d'`
	for name in $ch_ld_name
	do
		mysql="set names utf8;select chinese_name from channel_store where status=5 and extra_flag<=128 and extra_flag<>0 and english_name='$name';"
        	db "dtvs" "$mysql"
		ld_chinese_name+=`echo "${cmd}_ld " | grep -vE "chinese_name"`
	done
	result=`echo "$ld_chinese_name" | sed 's/ /\n/g' |sed '/^$/d'|grep -v "^_"`
}
#把数据转换成json格式
function transfer(){
zb_name="$name_channel_china"
COUNT=`echo "$zb_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$zb_name" | while read LINE; 
		do
    			echo -n '{"{#CHANNELNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}
}
#main
function main(){
	mysql="set names utf8;select f_record_udp_dir,f_work_flag from t_record_channel_info"
        db "dtvs" "$mysql"
        name_ld=`echo "$cmd" | grep -vE "f_record_udp_dir|f_work_flag" |awk 's=0;s=and($NF,4);{if(s==4) print}' | sort -u|awk '{print $1}'`
	for name in $name_ld
	do
		mysql="set names utf8;select chinese_name from channel_store where status=5 and extra_flag<=128 and extra_flag<>0 and english_name='$name';"
		db "dtvs" "$mysql"
		chinese_name+=`echo "${cmd} " | grep -vE "chinese_name"`
	done
	result01=`echo "$chinese_name" | sed 's/ /\n/g' |sed '/^$/d'`
	chennel_select
	name_channel_china=`echo "$result $result01" | sed 's/ /\n/g' |sed '/^$/d'`
	transfer
}
main
