#!/bin/bash
#
#	by wangdd 2016/05/16
#
#
#这个脚本的主要作用是,从zabbix数据库中获取相应的数据提供给前端，用于数据的展现
#
#
args=$1
m_time=`date +%s`
leng=`echo "${#m_time}-3"|bc`
new_clock=`expr substr "$m_time" 1 $leng`
dbip=`cat /homed/config_comm.xml | grep "mt_mainsrv_ip" |awk -F'[<>]' '{print $3}'`
user="zabbix"
passwd="zabbixpass"
db="zabbix"
mysql_cmd="mysql -B -u$user -p$passwd -h$dbip $db -e"
#-------------------------------------------------------
#获取mysql监控的基本信息
function deal_data(){
	datas=`$mysql_cmd "select hostid,itemid from items where key_ like '"mysql.monitor[mysql_info]"' and templateid is not NULL;" | grep -iv 'itemid'|sort -nk 1`
	echo "$datas" | while read line;
		do
			hostid=`echo "$line"| awk '{print $1}'`
			itemid=`echo "$line"| awk '{print $2}'`	
			sql="select value from history_log where itemid=$itemid and clock like '"${new_clock}%"' order by clock desc limit 1"
			result=`$mysql_cmd "$sql" | grep -iv 'value'`
			echo $hostid"|"$result|awk 'BEGIN{ORS=""}{print}'
	done
}

#-------------------------------------------------------
#获取云平台的服务分布
function get_homed_data(){
description="db_router 数据库写入路由服务|db_writer 数据库写入队列服务|dtvs 提供节目信息管理业务|iacs 提供用户接入业务|iclnd 提供日历应用业务|icore 电视社区服务|icrawler 提供采集资讯业务|iepgs 提供EPG信息采集业务|ilogmaster 提供集群服务管理功能|ilogslave 推流和API业务|imsgs 提供信息交换业务|ipwed 提供图文应用业务|isas 第三方服务接入服务|itimers 提供定时器应用业务|iuds 提供域名解析业务|iusa 账号中心接入服务|iusm 供帐号中心服务|redis 提供数据的缓存功能|tsg 提供录流、生成直播海报业务"
	server_des=`echo "$description" | sed 's/|/\n/g'`
	sql="select h.name,i.hostid,i.itemid,i.name from items i left join hosts h on h.hostid=i.hostid where i.key_ like '"homed.status%"' and (i.templateid is NULL and i.key_ not like '"%#%"' and i.key_ not like '"%httpd%"' and i.key_ not like '"%crond%"' and i.key_ not like '"%searchd%"') group by i.name,i.itemid;"
        result=`$mysql_cmd "$sql"|grep -v 'name'`
        data01=`echo "$result"|awk '{print $1,$2,$3,$4}' |awk '{s[$NF]++}END{for(key in s) print key,s[key]}' | sort -nk 1`
        data02=`echo "$result"| awk '{print $1,$2,$4}'| awk '{s[$NF]=s[$NF]"|"$2}END{for(key in s) print key,s[key]}' | sort -nk 1`
        data=`echo -e "$data01""\n""$data02"|awk '{s[$1]=s[$1]" "$2}END{for(key in s) print key,s[key]}'|sort -nk 1`
}

#-------------------------------------------------------
#
#-------------------------------------------------------
#入口
case $args in
	get_mysql_info)
		deal_data
		;;
	get_homed_info)
		get_homed_data
		rs=`echo -e "$data""\n""$server_des"`
		echo "$rs" |awk '{a[$1]=a[$1]" "$2" "$3}END{for(key in a) print key,a[key]}' | sort -k 1 |awk '{print $1,$2,$4,$3"#"}'
		;;
	*)
		echo "ERROR"
		;;
esac
