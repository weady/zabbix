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
#性能指标计算方式:
#  使用mysqladmin extended-status命令获得的MySQL的性能指标，默认为累计值。如果想了解当前状态，需要进行差值计算；加上参数 --relative(-r)，就可以看到各个指标的差值，配合参数--sleep(-i)就可以指定刷新的频率
#    1. tps/qps
#      tps: Transactions Per Second，每秒事务数；
#      qps: Queries Per Second每秒查询数；
#      通常有两种方法计算tps/qps：
#      方法1：基于  com_commit、com_rollback 计算tps，基于 questions  计算qps。
#        TPS = Com_commit/s + Com_rollback/s
#        其中，
#        Com_commit /s= mysqladmin extended-status --relative --sleep=1|grep -w Com_commit
#        Com_rollback/s = mysqladmin extended-status --relative --sleep=1|grep -w Com_rollback
#        QPS 是指MySQL Server 每秒执行的Query总量，通过Questions (客户的查询数目)状态值每秒内的变化量来近似表示，所以有：
#        QPS = mysqladmin extended-status --relative --sleep=1|grep -w Questions
#        仿照上面的方法还可以得到，mysql每秒select、insert、update、delete的次数等，如：
#        Com_select/s = mysqladmin extended-status --relative --sleep=1|grep -w Com_select
#        Com_select/s：平均每秒select语句执行次数
#        Com_insert/s：平均每秒insert语句执行次数
#        Com_update/s：平均每秒update语句执行次数
#        Com_delete/s：平均每秒delete语句执行次数
#      方法2: 基于com_%计算tps ,qps
#        tps= Com_insert/s + Com_update/s + Com_delete/s
#        qps=Com_select/s + Com_insert/s + Com_update/s + Com_delete/s
#    2. 线程状态
#      threads_running：当前正处于激活状态的线程个数
#      threads_connected：当前连接的线程的个数
#    3. 流量状态
#      Bytes_received/s：平均每秒从所有客户端接收到的字节数，单位KB
#      Bytes_sent/s：平均每秒发送给所有客户端的字节数，单位KB
#    4. innodb文件读写次数
#      innodb_data_reads：innodb平均每秒从文件中读取的次数 
#      innodb_data_writes：innodb平均每秒从文件中写入的次数
#      innodb_data_fsyncs：innodb平均每秒进行fsync()操作的次数
#    5. innodb读写量
#      innodb_data_read：innodb平均每秒钟读取的数据量，单位为KB
#      innodb_data_written：innodb平均每秒钟写入的数据量，单位为KB
#    6. innodb缓冲池状态
#      innodb_buffer_pool_reads: 平均每秒从物理磁盘读取页的次数
#      innodb_buffer_pool_read_requests: 平均每秒从innodb缓冲池的读次数（逻辑读请求数）
#      innodb_buffer_pool_write_requests: 平均每秒向innodb缓冲池的写次数
#      innodb_buffer_pool_pages_dirty: 平均每秒innodb缓存池中脏页的数目 
#      innodb_buffer_pool_pages_flushed: 平均每秒innodb缓存池中刷新页请求的数目
#      innodb缓冲池的读命中率
#      innodb_buffer_read_hit_ratio = ( 1 - Innodb_buffer_pool_reads/Innodb_buffer_pool_read_requests) * 100
#      Innodb缓冲池的利用率
#      Innodb_buffer_usage =  ( 1 - Innodb_buffer_pool_pages_free / Innodb_buffer_pool_pages_total) * 100
#    7. innodb日志
#      innodb_os_log_fsyncs: 平均每秒向日志文件完成的fsync()写数量 
#      innodb_os_log_written: 平均每秒写入日志文件的字节数
#      innodb_log_writes: 平均每秒向日志文件的物理写次数
#      innodb_log_write_requests: 平均每秒日志写请求数
#    8. innodb行
#      innodb_rows_deleted: 平均每秒从innodb表删除的行数
#      innodb_rows_inserted: 平均每秒从innodb表插入的行数
#      innodb_rows_read: 平均每秒从innodb表读取的行数
#      innodb_rows_updated: 平均每秒从innodb表更新的行数
#      innodb_row_lock_waits:  一行锁定必须等待的时间数
#      innodb_row_lock_time: 行锁定花费的总时间，单位毫秒
#      innodb_row_lock_time_avg: 行锁定的平均时间，单位毫秒
#    9. MyISAM读写次数
#      key_read_requests: MyISAM平均每秒钟从缓冲池中的读取次数 
#      Key_write_requests: MyISAM平均每秒钟从缓冲池中的写入次数
#      key_reads : MyISAM平均每秒钟从硬盘上读取的次数
#      key_writes : MyISAM平均每秒钟从硬盘上写入的次数
#    10. MyISAM缓冲池
#      MyISAM平均每秒key buffer利用率
#      Key_usage_ratio =Key_blocks_used/(Key_blocks_used+Key_blocks_unused)*100
#      MyISAM平均每秒key buffer读命中率
#      Key_read_hit_ratio=(1-Key_reads/Key_read_requests)*100
#      MyISAM平均每秒key buffer写命中率
#      Key_write_hit_ratio =(1-Key_writes/Key_write_requests)*100
#    11. 其他
#      slow_queries: 执行时间超过long_query_time秒的查询的个数（重要）
#      sort_rows: 已经排序的行数
#      open_files: 打开的文件的数目
#      open_tables: 当前打开的表的数量
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
				echo $host_name"|"$m_ip"|"Master"|"$stat"|""--""|"$m_status_file"|"$m_status_postion"|""--""|""--""|""--""|"$conn_nums"|"$m_result_nu
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
				echo $host_name"|"$s_ip"|"Slave"|"$IO";"$SQL"|"$s_status_Master_Host"|"$s_status_Master_Log_File"|"$s_status_Read_Master_Log_Pos"|"$s_status_Read_Master_Log_Pos"|"$s_status_Exec_Master_Log_Pos"|"$s_status_Seconds_Behind_Master"|"$conn_nums"|"$s_result_nu
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
