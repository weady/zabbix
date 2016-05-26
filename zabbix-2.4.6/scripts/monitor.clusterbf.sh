#!/bin/bash
#
#	by wangdd 2016/04/09
#

# 这个脚本主要用于获取集群中的并发连接数
# 开发逻辑
# 集群并发数开发逻辑
# 1.涉及到的表
# t_dss_stat_playc_total_%d 	//当前点播总数统计
# t_dss_stat_playc_stb_%d //机顶盒当前播放数目统计
# t_dss_stat_playc_smartcard_%d	//智能卡当前播放
# t_dss_stat_playc_mobile_%d	//手机端当前播放
# t_dss_stat_playc_pad_%d		//pad端当前播放
# t_dss_stat_playc_pc_%d		//pc 端移动播放
# t_dss_stat_server_info	//通过f_dss_stat_server_typeid字段获取logslave的所有服务ID，用于汇总数据
# 2. 传入两个变量 $1 $2
# $1 是设备类型确定表 $1[total,stb,smartcard,mobile,pad,pc]
# $2 是取值字段,确定从数据库获取的字段 $2[total,movie,tr,ts,kts,live,d]
#
#修改 $2 是取值字段,确定从数据库获取的字段 $2[total,movie,tr,ts_total,live] 合并了普通时移和一键时移，取消下载
#
#--------------------------------------------------------
#定义基本的公共变量
device_type=$1
value=$2
host=`cat /homed/config_comm.xml  | grep 'mt_db_ip' | awk -F '[><]' '{print $3}'`
user='root'
passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
database='homed_maintain'
mysql_cmd="mysql -B -u$user -p$passwd -h$host $database"
sql_serverid="select f_dss_stat_server_typeid from t_dss_stat_server_info where f_dss_stat_server_info like 'ilogslave%'"
ilogslaveid_lists=`$mysql_cmd -e "$sql_serverid" | grep -v 'f_dss_stat_server_typeid'`

#--------------------------------------------------------
#定义数据处理函数
function deal_data(){
	table=$1
	sum=0
	for id in $ilogslaveid_lists
	do
		get_sql="select f_${value}_current from ${table}${id} order by f_time desc limit 1;"
        	result=`$mysql_cmd -e "$get_sql" | grep -v "f_${value}_current"`
		if [ -z $result ];then
			result=0
		fi
		sum=`echo $result + $sum | bc`
	done
	echo $sum
}

#--------------------------------------------------------
#定义数据处理函数,汇总ts,kts,d三者的数据
function mege_data(){
	table=$1
	sum=0
	for id in $ilogslaveid_lists
	do
		mege_sql="select f_ts_current,f_kts_current from ${table}${id} order by f_time desc limit 1;"
		result=`$mysql_cmd -e "$mege_sql" | grep -v "current" | awk '{print sum=$1+$2}'`
		if [ -z "$result" ];then
                        result=0
                fi
                sum=`echo $result + $sum | bc`
        done
        echo $sum
}

#--------------------------------------------------------
#
function result_fun(){
	if [ "$value" == "ts_total" ];then
		mege_data "t_dss_stat_playc_${device_type}_"
        else
               	deal_data "t_dss_stat_playc_${device_type}_"
        fi
}

#--------------------------------------------------------
#定义数据处理函数
case $device_type in
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
	total_ks)
		mege_data "t_dss_stat_playc_${value}_"
		;;
	*)
		echo "ERROR"
		;;
esac
	
