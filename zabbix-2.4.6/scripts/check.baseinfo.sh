#!/bin/bash
#
#
#	wangdd 2016/03/10

name=$1
#------------------------------------------------------------------------
#获取的系统的硬件信息，操作系统版本
function get_sys_info(){
        system_info=`cat /etc/redhat-release | sed 's/\(.*\) (.*/\1/g'`
        type=`dmidecode | grep -A 4 "System Information"`
        system_type=`echo "$type" | sed 's/\n/ /g'`
        name=`echo "$type" | grep "Manufacturer" | awk '{print $2}'`
        Product=`echo "$type" | grep "Product"|awk -F':' '{print $2}'`
        Serial=`echo "$type" | grep "Serial"|awk -F ':' '{print $2}' | sed 's/ //g'`
        echo $system_info"|"$name $Product"|"$Serial
}

#------------------------------------------------------------------------
#获取主机上运行的homed服务名
function base_environment(){
	path="/homed"
	cd /homed
	source $path/allips.sh
	redis_ips_list="$redis_ips"
	tsg_ips_list="$tsg_ips"
	local_ips=`ifconfig | grep "inet addr:" | awk -F ':' '{print $2}' | awk '$1 !~ /^127/ {print $1}'`
	pro_name_tmp=`grep "^_.*" $path/start.sh | awk -F" " '{print $5}' | awk -F"['.]" '{print $2}' | sed '/^$/d' | sort -u`
}
#
function redis_add(){
for ip01 in $redis_ips
do
        for ip02 in $local_ips
        do
                if [ "$ip01" == "$ip02" ];then
                        tmp01=`echo "$pro_name_tmp" redis`
                fi
        done
done
}

function tsg_add(){
for ip01 in $tsg_ips
do
        for ip02 in $local_ips
        do
                if [ "$ip01" == "$ip02" ];then
                        tmp02=`echo "$pro_name_tmp" tsg`
                fi
        done
done
}
#
function get_homed_server_name(){
	base_environment
	redis_add
	tsg_add
	[[ -z "$tmp01" ]] && pro_name="$tmp02"
	[[ -z "$tmp02" ]] && pro_name="$tmp01"
	[[ ! -z "$tmp01"  &&  ! -z "$tmp02" ]] && pro_name=`echo "$tmp02" redis`
	[[ -z "$tmp02" && -z "$tmp01" ]] && pro_name="$pro_name_tmp"
	#pro_name=`echo "$pro_name" | sed 's/ /|/g'`	
	echo $pro_name
	
}

#------------------------------------------------------------------------
#从zabbix数据中获取出实时的告警信息，提供给前端的展示
function get_alerts(){
	host=`cat /usr/local/zabbix/etc/zabbix_agentd.conf | grep -vE "#|^$" | grep "Server\>" |awk -F '=' '{print $NF}'`
	user="zabbix"
	passwd="zabbixpass"
	database="zabbix"
	mysqlcmd="mysql -B -u$user -p$passwd -h$host $database -e"
	sql="select t.lastchange,t.description,h.name,t.priority
                    from items i
                    left join hosts h on i.hostid = h.hostid
                    left join functions f on i.itemid = f.itemid
                    left join triggers t on f.triggerid = t.triggerid
                    where t.status = 0 and value=1 group by t.description ORDER BY lastchange desc,description;"
	result=`$mysqlcmd "$sql"`
	alert_lists=`echo "$result" | grep -v "lastchange"`
	tmp=`echo "$alert_lists"| sed 's/[[:space:]]/ /g'`
	alert=`echo "$tmp" | sed 's/\(^[0-9]*\) \(.*\) \([s|m].*\) \([2|4]\)/\1|\2|\3|\4/g'`
	echo "$alert"
}
#------------------------------------------------------------------------
#主入口
case $name in
	disk_num)
		pro_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		count=`echo "$pro_name" |wc -l`
		echo $count
		;;
	disk_name)
		disk_name=`cat /proc/diskstats | awk '$3~/sd.*[a-z]$/ {print $3}' | sort`
		echo $disk_name
		;;
	cpu_type)
		core_num=`cat /proc/cpuinfo | grep "name" | wc -l`
		type=`cat /proc/cpuinfo | grep "name" | awk '{print $4,$5,$7,$NF }' | head -n 1`
		echo "$type $core_num 核"
		;;
	cpu_top5)
		name=`top -b n 1 | tail -n +8 | awk '{s[$NF]+=$9} END{for(key in s) print s[key],key}' | sort -nrk 1 | head -n 5 | awk -F '.' 'BEGIN{ORS="|"}{print $1"."$2}'`
                echo $name
		;;
	mem_top5)
		name=`top -b n 1 | tail -n +8 | awk '{s[$NF]+=$10} END{for(key in s) print s[key],key}' | sort -nrk 1 | head -n 5 | awk -F '.' 'BEGIN{ORS="|"}{print $1"."$2}'`
                echo $name
		;;
	ip_list)
		net_ip=`ifconfig |grep  -e 'Link encap' -A1 | grep -v '\-\-' | sed 'N;s/\n//' | awk -F '[[:space:]]*' '{print $1,$7}' | awk -F '[: ]' '{print $1,$NF}' | grep -v 'lo' | awk 'BEGIN{ORS="|"} {print}'`
		echo $net_ip
		;;
	sys_info)
		get_sys_info
		;;
	homed_service_name)
		get_homed_server_name
		;;
	alert_info)
		get_alerts
		;;
	*)
		echo "Error"
		exit
esac
