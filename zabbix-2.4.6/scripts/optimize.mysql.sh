#!/bin/bash
#
#This scritp used to delete 7 days ago datas of zabbix.history
#
#	by wangdd 2015/10/22
#

user="zabbix"
pass="zabbixpass"
db="zabbix"
host="127.0.0.1"
cmd=`which mysql`
dt=`date +%s -d "7 days ago" `
MYSQL="${cmd} -u$user -h$host -p$pass zabbix"
#查询出zabbix数据库中前十的表
mysql_cmd="select table_name,(data_length+index_length)/1024/1024 as total_MB, table_rows from information_schema.tables where table_schema='zabbix' order by total_MB DESC limit 10\G;"
#需要处理的表，一般就是history类型的表,通过表中的clock字段进行处理，clock字段是时间戳的格式
tables="history history_uint history_text history_log history_str acknowledges alerts auditlog events"
function select_table(){
	${cmd} -u$user -h$host -p$pass -e "$mysql_cmd"
}
#delete 7天前的hisory数据
function opt_table(){
	for table in $tables
	do
		$MYSQL -e "delete from $table where clock <$dt;"
		$MYSQL -e "optimize table $table"
	done
}
select_table
#opt_table
