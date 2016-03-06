#!/bin/bash
#
#这个脚本的主要作用是补发homed_ilog库中的sms_log表中发送失败的邮件
#
#
#	by wangdd 2016/01/27


now_hour=`date +%Y:%m:%d-%H`
now_day=`date +%Y:%m:%d`
year=`date +%Y`
dbip=`cat /homed/config_comm.xml | grep 'mt_db_ip' | awk -F '[<>]' '{print $3}'`
user="root"
password=`cat /homed/config_comm.xml | grep 'mt_db_pwd' | awk -F '[<>]' '{print $3}'`
db="homed_ilog"
sql_del="delete from sms_log where time not like '${year}%'"
sql_new_mes="select msg_content from sms_log where time like '${now_hour}%' and result = 'failed'"
sql_reset="update sms_log set result='success' where time like '${now_hour}%' and result = 'failed'"
reset_data=`mysql -u$user -p$password -h$dbip $db -e "${sql_del}"`
result=`mysql -u$user -p$password -h$dbip $db -e "${sql_new_mes}"`
data=`echo "$result" | grep -v "msg_content"`
update_data=`mysql -u$user -p$password -h$dbip $db -e "${sql_reset}"`
if [ -z "$result" ];then
	echo "OK"
else 
	echo "$data"
fi
