#!/bin/bash
#
#这个脚本用于调用数据库中的存储过程，对表进行分区
#
#	by wangdd 2015/10/20

user="zabbix"
pass="zabbixpass"
db="zabbix"
host="127.0.0.1"
mysql -B -u$user -h$host -p$pass zabbix -e "CALL create_zabbix_partitions();"

