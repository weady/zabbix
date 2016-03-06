#!/bin/bash
#
#
#
path="/usr/local/zabbix/etc"
function modity_ip(){
ip=`cat $path/zabbix_agentd.conf | grep -vE "#|^$" | grep -w "Hostname" |awk -F '=' '{print $NF}'`
zb_server="192.168.52.214"
new_ip="$1"
sed -i "s/$ip/$new_ip/g" $path/zabbix_agentd.conf
sed -i "s/192.168.3.114/$zb_server/g" $path/zabbix_agentd.conf
}
#cat $path/zabbix_agentd.conf | grep -vE "#|^$"
modity_ip
rm -f $0
