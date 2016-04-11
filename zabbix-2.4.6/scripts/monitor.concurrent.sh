#!/bin/bash
#
#	by wangdd 2016/04/07
#
#这个脚本主要是获取并发数的信息
#
#使用的数据库homed_maintain
#涉及到的表:
#ilogslave服务产生的原始数据表: %d代表服务号
#1.原始数据
#t_dss_stat_playc_total_%d 	//当前点播总数统计
#t_dss_stat_playc_stb_%d //机顶盒当前播放数目统计
#t_dss_stat_playc_smartcard_%d	//智能卡当前播放
#t_dss_stat_playc_mobile_%d	//手机端当前播放
#t_dss_stat_playc_pad_%d		//pad端当前播放
#t_dss_stat_playc_pc_%d		//pc 端移动播放
#2.保留3天的原始数据
#3.利用原始数中的均值，用于作图
#数据字段说明:
#f_total_average---总点播均数 f_movie_average---电影均数 f_tr_average---回看均数
#f_ts_average---一般时移均数 f_kts_average---一键时移均数 f_live_average---直播均数
#f_d_average---下载均数 
#传入的三个参数，$1,$3 确定了数据表，$2确定了查询字段
# $1 是通过check.concurrent.sh 脚本获取的{#SRVID} $2 取值范围是[total,movie,tr,ts,kts,live,d]
# $3 的取值范围[total,stb,smartcard,mobile,pad,pc]

serviceid=$1 
value=$2
equipment_type=$3
date_time=`date +%Y-%m-%d -d "3 days ago"`
host=`cat /homed/config_comm.xml  | grep 'mt_db_ip' | awk -F '[><]' '{print $3}'`
user='root'
passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
database='homed_maintain'
mysql_cmd="mysql -B -u$user -p$passwd -h$host $database"

#处理数据
function deal_data(){
	table=$1
	get_sql="select f_${value}_average from $table order by f_time desc limit 1;"
	result=`$mysql_cmd -e "$get_sql" | grep -v "f_${value}_average"`
	#清除三天前的数据
	delete_sql="delete from $table where f_time < '"$date_time"'"
	delete_old_data=`$mysql_cmd -e "$delete_sql"`
	if [ -z $result ];then
		echo "0"
	else
		echo $result
	fi
}

case $3 in
	total)
		deal_data "t_dss_stat_playc_total_${serviceid}"
		;;
	stb)
		deal_data "t_dss_stat_playc_stb_${serviceid}"
		;;
	smartcard)
		deal_data "t_dss_stat_playc_smartcard_${serviceid}"
		;;
	mobile)
		deal_data "t_dss_stat_playc_mobile_${serviceid}"
		;;
	pad)
		deal_data "t_dss_stat_playc_pad_${serviceid}"
		;;
	pc)
		deal_data "t_dss_stat_playc_pc_${serviceid}"
		;;
	*)
		echo "Error"
		;;
esac
