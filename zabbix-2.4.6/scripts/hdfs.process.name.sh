#!/bin/bash
#
#This is script is used to monitor hadoop's namenode or datanode status
#hadoop 版本为2.4.6和1.2.1
#
#       by wangdd 2016/03/31
source /etc/profile
cmd=`type hadoop|awk '{print $NF}'`
ver=`$cmd version|head -n 1|tr -d '[a-zA-Z- ]'`
host_name=`hostname`

#--------------------------------------
function add_journal(){
        for host in $JournalNode
        do
                if [ "$host" == "$host_name" ];then
                        tmp01=`echo "$pro_name_tmp" JournalNode`
                fi
        done

}

#--------------------------------------
function add_quorum(){
        for host in $QuorumPeerMain
        do
                if [ "$host" == "$host_name" ];then
                        tmp02=`echo "$pro_name_tmp" QuorumPeerMain`
                fi
        done


}

#--------------------------------------
function result_v2(){
        if [ $host_name == "master" -o $host_name == "secondmaster" ];then
                pro_name=$name_process
        else
                add_journal
                add_quorum
                [[ -z "$tmp01" ]] && pro_name="$tmp02"
                [[ -z "$tmp02" ]] && pro_name="$tmp01"
                [[ ! -z "$tmp01"  &&  ! -z "$tmp02" ]] && pro_name=`echo "$tmp02" JournalNode`
                [[ -z "$tmp02" && -z "$tmp01" ]] && pro_name="$pro_name_tmp"
        fi
}

#--------------------------------------
function result_v1(){
	if [ $host_name == "master" ];then
		pro_name="NameNode"
	elif [ $host_name == "secondmaster" ];then
		pro_name="SecondaryNameNode"
	else
		pro_name="DataNode"
	fi
}

#--------------------------------------
function zabbix_data(){
	pro_name=`echo "$pro_name" | sed 's/ /\n/g'`
	COUNT=`echo "$pro_name" |wc -l`
	INDEX=0
	echo {'"data"':[
        	echo "$pro_name" | while read LINE; 
                	do
                        	echo -n '{"{#HADOOPNAME}":"'$LINE'"}'
                        	INDEX=`expr $INDEX + 1`
                        	if [ $INDEX -lt $COUNT ]; then
                                	echo ","
                       		fi
                	done
        echo ]}
}

#--------------------------------------
function main(){
        if [ "$ver" == "2.6.4" ];then
		name_process="NameNode DFSZKFailoverController"
		pro_name_tmp="DataNode"
                config_file="/hadoop/hadoop-${ver}/etc/hadoop"
                JournalNode=`cat $config_file/hdfs-site.xml | grep 'qjournal' | awk -F '[/:;]' '{for(i=1;i<=NF;i++) if($i ~ /slave/) print $i}'`
                QuorumPeerMain=`cat $config_file/core-site.xml | grep -A 1 'zookeeper.quorum' | grep -v 'zookeeper.quorum' | awk -F '[>/:;,]' '{for(i=1;i<=NF;i++) if($i ~ /slave/) print $i}'`
		result_v2
		zabbix_data
        elif [ "$ver" == "1.2.1" ];then
		result_v1
		zabbix_data
        fi
}
#--------------------------------------
main
