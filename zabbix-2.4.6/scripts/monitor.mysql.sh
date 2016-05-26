#!/bin/bash
#
#	by wangdd 2016/04/21
#
#该脚本主要作用获取mysql基本信息以及性能状态
#

argv=$1
value=${argv#*_}
maintainip=`cat /homed/config_comm.xml  | grep 'mt_mainsrv_ip' | awk -F '[><]' '{print $3}'`
local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
mysql_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u`
mysql_ips=`echo "$mysql_ips" "$maintainip"`
#-----------------------------------------
#数据库基本配置
for local_ip in $local_ips
do
	for mysql_ip in $mysql_ips
	do
		if [ "$local_ip" == "$mysql_ip" ];then
			db_ip=$mysql_ip
		fi
	done
done
user="root"
passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
database=""
mysql_cmd="mysql -B -u$user -p$passwd -h$db_ip $database -e"
#-----------------------------------------
#获取mysql基本配置信息函数
function get_info(){
	type=$1
	var=$2
	info_sql="show global $type where Variable_name in ('"$var"')"
	result=`$mysql_cmd "$info_sql" | grep -iv 'value'|awk '{print $2}'`
}
function get_status_info(){
	type=$1
	var=$2
	info_sql="show $type where Variable_name in ('"$var"')"
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
#  1Qcache Status
#    Qcache queries hits ratio:Com_select/Qcache_hits 缓存查询命中率
#    Qcache hits inserts ratio:Qcache_inserts/Qcache_hits 缓存插入命中率
#    Qcache memory used ratio:Qcache_free_memory/query_cache_size 缓存内存利用率
#  2.key buffers 命中率
#    key_buffer_read_hits:1-(key_reads / key_read_requests) * 100%
#    key_buffer_write_hits:1-(key_writes / key_write_requests) * 100%
#    key buffer used ratio(used/size):Key_blocks_used/variables.key_cache_block_size
#  3.InnoDB Buffer命中率
#    Innodb_buffer_read_hits = (1 - innodb_buffer_pool_reads / innodb_buffer_pool_read_requests) * 100%
#  4.Query Cache命中率
#    Query_cache_hits = (Qcahce_hits / (Qcache_hits + Qcache_inserts )) * 100%;
#  5.Thread Cache 命中率
#    Thread_cache_hits = (1 - Threads_created / connections ) * 100%
#  6.锁表率
#    Table locks waited ratio(waited/immediate):Table_locks_waited/Table_locks_immediate
#  7.慢查询率
#    Slow queries Ratio(Slow/Questions):Slow_queries/Questions
#  8.线程缓存命中率
#    Thread cache hits:Threads_created/Connections
#  9.运行线程数
#    Threads_running
function ratio(){
	a=$1
	b=$2
	if [ "$b" -eq 0 ];then
		ratio=0
	else
		ratio=`echo "scale=2;($a/$b)*100" | bc`
	fi
}
function dratio(){
	a=$1
	b=$2
	if [ "$b" -eq 0 ];then
		ratio=0
	else
		ratio=`echo "scale=2;(1-$a/$b)*100" | bc`
	fi
}
function get_value(){
	arg01=$1
	arg02=$2
	get_info "variables" "query_cache_size"	
	q_cache_size=$result
	get_info "variables" "key_cache_block_size"
	k_cache_block_size=$result	
	value="show global status"
	result=`$mysql_cmd "$value" | grep -vi 'value'`
	value01=`echo "$result" | grep -i "\<$arg01\>" |awk '{print $2}'`
	value02=`echo "$result" | grep -i "\<$arg02\>" |awk '{print $2}'`
}
#-----------------------------------------
#数据库基本信息
function mysql_base_info(){
        #local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
        #mysql_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u`
	host_name=`hostname`
	mysql_master_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u | awk '{print $1}'`	
	mysql_slave_ips=`cat /homed/allips.sh | grep "export.*_mysql_ips.*[0-9]" | awk -F '"' '{print $2}' | sort -u | awk '{print $2}'`
	mysql_master_ips=`echo "$mysql_master_ips $maintainip"`
	for l_ip in $local_ips
	do
		for m_ip in $mysql_master_ips
		do
			if [ "$l_ip" == "$m_ip" ];then
				m_sql="show databases;"
				m_sql_status="show master status"
				#客户端连接进程数
               			conn_nums=`$mysql_cmd "show processlist" | grep -iv "User"|wc -l`
				m_status_file=`$mysql_cmd "$m_sql_status"| grep -v File|awk '{print $1}'`
				m_status_postion=`$mysql_cmd "$m_sql_status"| grep -v File|awk '{print $2}'`
				m_result=`$mysql_cmd "$m_sql"|grep -v "Database"`
				m_result_nu=`echo "$m_result"|wc -l`
				[[ -n "$m_status_file" ]] && stat="Yes"
				#序号|主机名|主机IP|主从关系|主从状态|Master_Host|二进制日志|Postion|Read_Master_Log_Pos|Exec_Master_Log_Pos|复制延迟|数据库数量|连接数|数据库列表
				echo $host_name"|"$m_ip"|"Master"|"$stat"|""--""|"$m_status_file"|"$m_status_postion"|""--""|""--""|""--""|"$conn_nums"|"$m_result_nu"#"
				break
			fi
		done
		for s_ip in $mysql_slave_ips
		do
			if [ "$l_ip" == "$s_ip" ];then
				s_sql="show databases;"
                                s_sql_status="show slave status\G"
                                s_status=`$mysql_cmd"$s_sql_status"`
				#客户端连接进程数
               			conn_nums=`$mysql_cmd "show processlist" | grep -iv "User"|wc -l`
                                s_status_IO=`echo "$s_status"| grep -v "row"|grep -E "Slave_IO_Running"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_SQL=`echo "$s_status"| grep -v "row"|grep -E "Slave_SQL_Running"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_Master_Host=`echo "$s_status"| grep -v "row"|grep -E "Master_Host"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_Master_Log_File=`echo "$s_status"| grep -v "row"|grep -E "\<Master_Log_File"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_Read_Master_Log_Pos=`echo "$s_status"| grep -v "row"|grep -E "\<Read_Master_Log_Pos"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_Exec_Master_Log_Pos=`echo "$s_status"| grep -v "row"|grep -E "\<Exec_Master_Log_Pos"|awk -F':' '{print $2}'|tr -d ' '`
                                s_status_Seconds_Behind_Master=`echo "$s_status"| grep -v "row"|grep -E "\<Seconds_Behind_Master"|awk -F':' '{print $2}'|tr -d ' '`
                                s_result=`$mysql_cmd"$s_sql"|grep -v "Database"`
                                s_result_nu=`echo "$s_result"|wc -l`
				if [ "$s_status_IO" == "Yes" ];then
					IO="Slave_IO Yes"
				else
					IO="Slave_IO No"
				fi
				if [ "$s_status_SQL" == "Yes" ];then
					SQL="Slave_SQL Yes"
				else
					SQL="Slave_SQL No"
				fi
				#序号|主机名|主机IP|主从关系|主从状态|Master_Host|二进制日志|Postion|Read_Master_Log_Pos|Exec_Master_Log_Pos|复制延迟|数据库数量|连接数|数据库列表
				echo $host_name"|"$s_ip"|"Slave"|"$IO";"$SQL"|"$s_status_Master_Host"|"$s_status_Master_Log_File"|"$s_status_Read_Master_Log_Pos"|"$s_status_Read_Master_Log_Pos"|"$s_status_Exec_Master_Log_Pos"|"$s_status_Seconds_Behind_Master"|"$conn_nums"|"$s_result_nu"#"
				break
			fi
			
		done
	done	
}
#-----------------------------------------
#主入口
case $argv in
	mysqlconfig_${value})
		#获取数据库的配置信息
		get_info "variables" "$value"
		echo $result
		;;
	mysqlstatus_${value})
		#获取数据库的状态信息
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
	cache_used_ratio)
		#缓存使用率
		get_value "Qcache_free_memory"
		cache_used_ratio=`echo "scale=2;($q_cache_size-$value01)/$q_cache_size *100" | bc`
		echo $cache_used_ratio
		;;
	Key_buffer_read_ratio)
		#key Buffer 命中率
		get_value "Key_reads" "Key_read_requests"
		dratio "$value01" "$value02"
		echo "$ratio"
		;;
	Key_buffer_write_ratio)
		#key Buffer 命中率
		get_value "Key_writes" "Key_write_requests"
		dratio "$value01" "$value02"
		echo "$ratio"
		;;
	Innodb_buffer_read_ratio)
		#InnoDB缓冲池的读命中率
		get_value "innodb_buffer_pool_reads" "innodb_buffer_pool_read_requests"
		if [ -z "$value01" -o -z "$value02" ];then
			echo 0
		else	
			dratio "$value01" "$value02"
			echo "$ratio"
		fi
		;;
	Query_cache_ratio)
		#Query Cache命中率
		get_value "Qcache_hits" "Qcache_inserts"
		Query_cache_ratio=`echo "scale=2;($value01/($value01+$value02))*100" | bc`
		echo $Query_cache_ratio
		;;
	Thread_cache_ratio)
		#Thread Cache 命中率
		get_value "Threads_created" "connections"
		dratio "$value01" "$value02"
                echo "$ratio"
                ;;
	Slow_queries_ratio)
		#慢查询率
		get_value "Slow_queries" "Questions"
		ratio "$value01" "$value02"
                echo "$ratio"
                ;;
	Innodb_buffer_pages_used_ratio)
		#Innodb缓冲池的利用率
		get_value "Innodb_buffer_pool_pages_free" "Innodb_buffer_pool_pages_total"
		if [ -z "$value01" -o -z "$value02" ];then
			echo 0
		else	
			ratio "$value01" "$value02"
			echo "$ratio"
		fi
		;;
	Innodb_buffer_pages_dirty_ratio)
		get_value "Innodb_buffer_pool_pages_dirty" "Innodb_buffer_pool_pages_total"
		if [ -z "$value01" -o -z "$value02" ];then
			echo 0
		else	
			ratio "$value01" "$value02"
			echo "$ratio"
		fi
		;;
	TPS)
		#每秒事务数
		get_value "Com_commit" "Com_rollback"
		TPS=`echo "$value01+$value02" | bc`
		echo $TPS
		;;
	mysql_info)
		#集群数据库的基本信息
		mysql_base_info
		;;
	con_num)
		#客户端连接进程数
		result=`$mysql_cmd "show processlist" | grep -iv "User"|wc -l`
		echo $result
		;;		
	*)
		echo "ERROR"
		exit
		;;
esac 
