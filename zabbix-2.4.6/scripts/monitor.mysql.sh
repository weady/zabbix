#!/bin/bash
#
#	by wangdd 2016/04/21
#
#该脚本主要作用获取mysql基本信息以及性能状态
#

argv=$1
value=${argv#*_}
#-----------------------------------------
#数据库基本配置
host="192.168.35.105"
user="root"
passwd="123456"
database=""
mysql_cmd="mysql -B -u$user -p$passwd -h$host $database -e"
#-----------------------------------------
#获取mysql基本配置信息函数
function get_info(){
	type=$1
	var=$2
	info_sql="show global $type where Variable_name in ('"$var"')"
	result=`$mysql_cmd "$info_sql" | grep -iv 'value'|awk '{print $2}'`
}
#-----------------------------------------
#获取master的相关信息的函数
function get_master_info(){
	var=$1
	master_sql="show master status"
	result=`$mysql_cmd "$master_sql" | grep -iv 'File'`
	if [ "$var" == "File" ];then
		result=`echo "$result" | awk '{print $1}'`
	elif [ "$var" == "Position" ];then
		result=`echo "$result" | awk '{print $2}'`
	fi
}
#-----------------------------------------
#获取slave的相关信息的函数
function get_slave_info(){
	var=$1
	slave_sql="show slave status\G"
	result=`$mysql_cmd "$slave_sql"|grep "\<$var" |awk '{print $2}'`
}
#-----------------------------------------
#获取innodb存储引擎的相关信息的函数
function get_innodb_info(){
	echo "innodb"
}
#-----------------------------------------
#获取myisam存储引擎的相关信息的函数
function get_myisam_info(){
	echo "myisam"
}
#-----------------------------------------
#获取缓存利用率，命中率的函数
#查询缓存利用率 = (query_cache_size – Qcache_free_memory) / query_cache_size * 100% 
#查询缓存命中率 = (Qcache_hits – Qcache_inserts) / Qcache_hits * 100%
#索引命中率 = 100-(Key_reads / Key_read_requests * 100)
function get_rate(){
	get_info "variables" "query_cache_size"	
	q_cache_size=$result
	value="show global status where Variable_name in ('Qcache_free_memory','Qcache_hits','Qcache_inserts','Key_reads','Key_read_requests')"
	result=`$mysql_cmd "$value" | grep -vi 'value'`
	q_free_m=`echo "$result" | grep 'Qcache_free_memory' | awk '{print $2}'`
	q_hits=`echo "$result" | grep 'Qcache_hits' | awk '{print $2}'`
	q_inserts=`echo "$result" | grep 'Qcache_inserts' | awk '{print $2}'`
	index_reads=`echo "$result" | grep 'Key_reads' | awk '{print $2}'`
	index_requests=`echo "$result" | grep 'Key_read_requests' | awk '{print $2}'`
	cache_used_rate=`echo "scale=2;($q_cache_size-$q_free_m)/$q_cache_size *100" | bc`
	cache_hit_rate=`echo "scale=2;($q_hits-$q_inserts)/$q_hits *100" | bc`
	index_hit_rate=`echo "scale=2;100-($index_reads/$index_requests *100)" | bc`
}
#-----------------------------------------
#主入口
case $argv in
	mysqlconfig_${value})
		get_info "variables" "$value"
		echo $result
		;;
	mysqlstatus_${value})
		get_info "status" "$value"
		echo $result
		;;
	master_${value})
		get_master_info "$value"
		echo $result
		;;
	slave_${value})
		get_slave_info "$value"
		;;
	cache_used_rate)
		get_rate
		echo $cache_used_rate
		;;
	index_hit_rate)
		get_rate
		echo $index_hit_rate
		;;
	*)
		echo "ERROR"
		exit
		;;
esac 
