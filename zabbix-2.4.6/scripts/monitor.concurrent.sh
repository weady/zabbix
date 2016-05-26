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
#3.利用原始数中的瞬时值，用于作图
#数据字段说明:
#f_total_current---总点播均数 f_movie_current---电影均数 f_tr_current---回看均数
#f_ts_current---一般时移均数 f_kts_current---一键时移均数 f_live_current---直播均数
#f_d_current---下载均数 
#传入的三个参数，$1,$3 确定了数据表，$2确定了查询字段
# $1 是通过check.concurrent.sh 脚本获取的{#SRVID} $2 取值范围是[total,movie,tr,ts,kts,live,d,ts_total]
# $3 的取值范围[total,stb,smartcard,mobile,pad,pc]

#--------------------------------------------------------
#通用变量
serviceid=$1 
value=$2
equipment_type=$3
date_time=`date +%Y-%m-%d -d "1 days ago"`
host=`cat /homed/config_comm.xml  | grep 'mt_db_ip' | awk -F '[><]' '{print $3}'`
user='root'
passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
database='homed_maintain'
mysql_cmd="mysql -B -u$user -p$passwd -h$host $database"

#--------------------------------------------------------
#处理数据
function deal_data(){
	table=$1
	get_sql="select f_${value}_current from $table order by f_time desc limit 1;"
	result=`$mysql_cmd -e "$get_sql" | grep -v "f_${value}_current"`
	#清除三天前的数据
	delete_sql="delete from $table where f_time < '"$date_time"'"
	delete_old_data=`$mysql_cmd -e "$delete_sql"`
	if [ -z $result ];then
		echo "0"
	else
		echo $result
	fi
}
#--------------------------------------------------------
#定义数据处理函数,汇总ts,kts,d三者的数据
function mege_data(){
        table=$1
        sum=0
        mege_sql="select f_ts_current,f_kts_current from ${table} order by f_time desc limit 1;"
        result=`$mysql_cmd -e "$mege_sql" | grep -v "current" | awk '{print sum=$1+$2}'`
        if [ -z "$result" ];then
        	echo "0"
       	else
                echo $result
	fi
}

#--------------------------------------------------------
#数据汇总处理
function result_fun(){
        if [ "$value" == "ts_total" ];then
                mege_data "t_dss_stat_playc_${equipment_type}_${serviceid}"
        else
                deal_data "t_dss_stat_playc_${equipment_type}_${serviceid}"
        fi
}

#--------------------------------------------------------
#主入口
case $3 in
	total)
		result_fun
		;;
	stb)
		result_fun
		;;
	smartcard)
		result_fun
		;;
	mobile)
		result_fun
		;;
	pad)
		result_fun
		;;
	pc)
		result_fun
		;;
	*)
		echo "Error"
		;;
esac
