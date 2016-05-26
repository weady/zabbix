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
	channel_lists=`echo "$cmd" | grep -vE "f_record_udp_dir|f_work_flag" |awk 's=0;s=and($NF,4);{if(s==4) print}' | sort -u|awk '{print $1}'`
	for channel_name in $channel_lists
	do
		if [[ "$channel_name" =~ _.*d$ ]];then
			d_channel=${channel_name%_*}
			tag=${channel_name#*_}
			mysql="set names utf8;select chinese_name from channel_store where status=5 and extra_flag<=128 and extra_flag<>0 and english_name='$d_channel';"
        		db "dtvs" "$mysql"
			chinese_name+=`echo "${cmd}_${tag} " | grep -vE "chinese_name"|sed 's/(/_/g'|tr -d ')'`
		else
			mysql="set names utf8;select chinese_name from channel_store where status=5 and extra_flag<=128 and extra_flag<>0 and english_name='$channel_name';"
        		db "dtvs" "$mysql"
			chinese_name+=`echo "${cmd} " | grep -vE "chinese_name"|sed 's/(/_/g'|tr -d ')'`
		fi
	done
	result=`echo "$chinese_name" | sed 's/ /\n/g' |sed '/^$/d'`
}
#-------------------------------------------------------------
#把数据转换成json格式
function transfer(){
zb_name="$result"
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
chennel_select
transfer
