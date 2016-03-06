#!/bin/bash
#
#This scripts used to monitor physical disk status
#
#	by wangdd 2015/11/26
#
#
path="/usr/local/zabbix"

#check raid status
function raid_status(){
line=`/opt/MegaRAID/MegaCli/MegaCli64 -cfgdsply -aALL -Nolog| grep -e "DISK GROUP:" -e "Physical Disk:" -e "Firmware state:"`
tmp=`echo "$line" | awk '/^DISK/{T=$0;next;}{print T":\t"$0;}' | awk -F ':' '$0 ~ /Firmware state/ {print $3,$4;next} {print $0}' | awk '/Physical/ {P=$0;next} {print P,$0}'`
online=`echo "$tmp" | grep "Online"`
Error=`/opt/MegaRAID/MegaCli/MegaCli64 -cfgdsply -aALL -Nolog | egrep -B 5 "Degraded" | grep 'Name' | awk -F ':' '{print $NF}'`
#fail=`echo "$line" | egrep "Failed|Rebuild"`
if [ -z "$Error" ];then
        echo "$online"
else
        echo "$Error Degraded"
fi
}
#check physical disk status
OK=""
Error=""
function P_disk_status(){
	disk_list=`/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL -Nolog| grep "Firmware state" | awk -F'[:,]' '{print $2}' | sed 's/ //g'`
	for disk_status in $disk_list
	do
		num=$[ $num + 1 ]
		if [ "$disk_status" == "JBOD" -o "$disk_status" == "Online" ];then
			 OK+=" Disk $num is OK | "
		else
			Error+=`echo "Disk $num is Error "`
		fi
	done
if [ -n "$Error" ];then
	echo "$Error"
else
	echo "$OK"
fi
}
#main
case $1 in
        raid)
                raid_status
                ;;
        disk)
                P_disk_status
                ;;
        *)
                echo "Error Input:"
esac
