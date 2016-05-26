#!/bin/bash
#
#
#	by wangdd 2015/10/30
#
#
last_split_ips=""
path="/usr/local/src"
rex1=[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}
rex2=[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}-[0-9]\{1,3\}
#function
function f_splitips(){
        local all_oldips=$1
        local newips=""
        local oldips
        for oldips in $all_oldips
        do
                local start_ip=${oldips%-*}
                local end=${oldips#*-}

                if [ "$end" == "$start_ip" ]
                then
                        if [ "$newips" == "" ]
                        then
                                newips=$start_ip
                        else
                                newips="$newips $start_ip"
                        fi
                else
                        start=${start_ip##*.}
                        local ip_header=${start_ip%.*}

                        local num
                        for((num=$start;num<=$end;num++))
                        do
                                if [ "$newips" == "" ]
                                then
                                        newips="$ip_header.$num"
                                else
                                        newips="$newips $ip_header.$num"
                                fi
                        done
                fi
        done


        #remove repeat ips
        if [ "$2" == "--norepeat" ]
        then
                local newips1=""
                local addip
                for addip in $newips
                do
                        if [ "$newips1" == "" ]
                        then
                                newips1="$addip"
                                continue
                        fi

                        local hasexist=""
                        local hasip
                        for hasip in $newips1
                        do
                                if [ "$hasip" == "$addip" ]
                                then
                                        hasexist="1"
                                        break
                                fi
                        done

                        if [ "$hasexist" == "" ]
                        then
                                newips1="$newips1 $addip"
                        fi
                done

                newips=$newips1 
        fi

        last_split_ips=$newips
}
#----------------------------------------------------------------------------------
#Install zabbix server
	
function ZB_server(){
    read -p " Your want into Zabbix Server to which slave(eg:slave14):" slave
	ip=`cat /etc/hosts | grep "$slave\>" | head -n 1|awk '{print $1}'`
	if [ -z "$ip" ];then
		echo "There is no this $slave"
		exit
	fi
	read -p " Databae IP:" dbip
    read -p " Databae user(root):" username
    read -p " Databae passwd:" password
    if [[ "$ip" =~ $rex1 ]];then
		echo "---- Install zabbix_server in $ip----"
		rsync $path/zabbix-2.4.6.tar.gz $ip:$path
		ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./scripts/zabbix_server_install.sh $ip $dbip $username $password"
		echo "Zabbix Server ip is $ip"
    else
        echo "Illegal IP"
    fi
}

#Install Zabbix_agent
function ZB_agent(){
	read -p "Input Zabbix Server ip:" sip
	#sip=`cat /homed/config_comm.xml | grep "mt_mainsrv_ip" |sed -re 's/.*>(.*)<.*$/\1/g'`
	read -p "Input Agent ips(eg:192.168.1.1-123 or 192.168.1.1):" ips
	[[ "$sip" =~ $rex1 ]] && serverip="$sip" || echo "Zabbix Server ip Error"
	if [[ "$ips" =~ $rex1 || "$ips =~ $rex2" ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		for ip in ${ip_list}
		do
			echo " Install zabbix_agent to $ip"
			rsync $path/zabbix-2.4.6.tar.gz $ip:$path
			ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./scripts/zabbix_agent_install.sh $serverip"
			check_ok "$ip" "zabbix_agent"
		done
	else
		echo "Illegal IP"
	fi
}
#check function
function check_ok(){
	if [ $? -eq 0 ];then
		echo "----$1 install $2 success----"
	else
		echo "----$1 install $2 failed----"
	fi
}
#contral zabbix_agent
function contral_agent(){
	read -p "Input Agent Ips(eg:192.168.1.1 or 192.168.1.1-100):" ips
	if [[ "$ips" =~ ^$rex1$ || "$ips" =~ ^$rex2$ ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		read -p "Choise one{status|start|restart|stop}:" command
		case $command in
		status)
			agent_comm
			;;
		start)
			agent_comm
			;;	
		restart)
			agent_comm
			;;	
		stop)
			agent_comm
			;;
		*)
			echo "Error"
			;;
		esac
	else
		echo "Error"
	fi
}
#command 
function agent_comm(){
	for ip in ${ip_list}
	do
		echo "------------$ip--------------------"
		ssh $ip "service zabbix_agent $command"
	done
}
#input zabbix_server ip
function check_ip(){
    read -p "Input ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
    if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
		f_splitips "$ip"
        ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
	else
		echo "Invalid IP"
		check_ip
	fi
}
#deploy softs
function deploy_softs(){
	soft_package=$1
	soft_name=$2
	argv=$3
	for ip in $ip_list
	do
		rsync -az $path/softs/$soft_package $ip:$path
		rsync -az $path/scripts/lamp_install.sh $ip:$path
		ssh $ip "cd $path;./lamp_install.sh $soft_name $argv"
	done
}
#Install some softs
function Install_soft(){
	read -p "Your want to install softs in the local host or the remote host(eg:local or remote):" targ
	if [ "$targ" == "remote" ];then
		check_ip
		read -p "Choise your want install soft:{php|mysql|apache} :" softname
		case $softname in
			php)
				deploy_softs "php-5.5.7-green.tar.gz" "php" "$targ"
				;;
			mysql)
				deploy_softs "mysql-5.5.33-green.tar.gz" "mysql" "$targ"
				;;
			apache)
				deploy_softs "apache-2.2.21-green.tar.gz" "apache" "$targ"
				;;
			*)
				echo "Usage {php|mysql|apache}"
				;;
		esac
	elif [ "$targ" == "local" ];then
		read -p "Choise your want install soft:{php|mysql|apache} :" softname
		cd $path
		./scripts/lamp_install.sh $softname
	else
		echo "Your should input local or remote!"
	fi
}
#-----------------------------------------------------------
function install_comm_server(){
	ser_name=$1
	for ip in $ip_list
        do
		if [ "$ser_name" == "ftp" ];then
                	rsync -az $path/scripts/ftp_install.sh $ip:$path
			read -p "Please input share directory:" share_path
                	ssh $ip "cd $path;./ftp_install.sh $share_path"
		elif [ "$ser_name" == "nfs" ];then
			rsync -az $path/scripts/nfs_install.sh $ip:$path
			read -p "Please input share directory:" share_path
			read -p "Please input allow network(eg:192.168.0.0/16):" allow_ip
			ssh $ip "cd $path;./nfs_install.sh $share_path $allow_ip"
		elif [ "$ser_name" == "dncp" ];then
			rsync -az $path/scripts/dhcp_install.sh $ip:$path
			read -p "Please input DHCP clients ip(eg:192.168.1.100-200):" clients_ip
			read -p "Please input getway IP" getwayip
			read -p "Please input DNS IP" dnsip
			ssh $ip "cd $path;./dhcp_install.sh $clients_ip $getwayip $dnsip"
		fi
        done
}
#install some server
function install_dhcp_ftp_nfs(){
	read -p "Your want to install softs in the local host or the remote host(eg:local or remote):" targ
	if [ "$targ" == "remote" ];then
		check_ip
		read -p "Choise your want install server:{ftp|dhcp|nfs}" server_name
		case $server_name in
			ftp)
				install_comm_server "ftp"
				;;
			dhcp)
				install_comm_server "dhcp"
				;;
			nfs)
				install_comm_server "nfs"
				;;
			*)
				echo "Usage {ftp|dhcp|nfs}"
				;;
		esac
	elif [ "$targ" == "local" ];then
		cd $path
		read -p "Choise your want install server:{ftp|dhcp|nfs}" ser_name
		if [ "$ser_name" == "ftp" ];then
                        read -p "Please input share directory:" share_path
			./scripts/ftp_install.sh $share_path
                elif [ "$ser_name" == "nfs" ];then
                        read -p "Please input share directory:" share_path
                        read -p "Please input allow network(eg:192.168.0.0/16):" allow_ip
			./scripts/nfs_install.sh $share_path $allow_ip
                elif [ "$ser_name" == "dncp" ];then
                        read -p "Please input DHCP clients ip(eg:192.168.1.100-200):" clients_ip
                        read -p "Please input getway IP" getwayip
                        read -p "Please input DNS IP" dnsip
			./scripts/dhcp_install.sh $clients_ip $getwayip $dnsip
                fi
	else
		echo "Your should input local or remote!"
	fi
	
}
#sync files to some where
function Sync(){
	check_ip
	read -p "Input source dir or files:" src
	read -p "Input destination dir or files:" dst
	if [ -z "$src" -o -z "$dst" ];then
		echo "Error"
	else
	for ip in ${ip_list} 
	do
		echo "-----Sync files to $ip-----"
		rsync -avz $src $ip:$dst
		[[ $? -eq 0 ]] && echo "SYNC Success" || echo "SYNC Failed"
        done
	fi
}
#Get or Put file to FTP
function ftp(){
	ftp_ip="ftp.xxxx.cn"
	username="xxxx"
	passwd="xxxxx"
	read -p "Input file(eg: put/get local_dir ftp_dir files):" method l_dir ftp_dir file
	echo "------------------------------------------------"
	echo "Start $method $file to  at `date +%Y-%m-%d-%T`"
	echo "------------------------------------------------"
/usr/bin/ftp -ivn $ftp_ip <<EOF
user $username $passwd
binary
lcd ${l_dir}
cd ${ftp_dir}
m${method} ${l_dir}  $file
bye
EOF
	echo "------------------------------------------------"
	echo "End ${method} $file at `date +%Y-%m-%d-%T`"
	echo "------------------------------------------------"
}
#-----------------------------------------------------------------------------------
#configure keepalived+LVS
#
function LVS(){
	if [ ! -f "/etc/keepalived/keepalived.conf" ];then
		read -p "Please input keepalived type(MASTER Or SLAVE):" lvs_type
		read -p "Please input LVS's priority:" lvs_priority
		read -p "Please input LVS's banlance algo(eg:rr wlc llc):" lvs_algo
		read -p "Please input your VIP:" vip_list
		read -p "Please input VIP binding interface:" bind_inter
		read -p "Please input port:" port_list
       	read -p "Please input real server ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
			f_splitips "$ip"
               		realip_list=$last_split_ips
		else
			echo "Invalid IP"
		fi
	else
		lvs_type="MASTER"
		lvs_priority="100"
		lvs_algo="rr"
		bind_inter="eth1"
		read -p "Please input your VIP:" vip_list
		read -p "Please input port:" port_list
       		read -p "Please input real server ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        	if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
			f_splitips "$ip"
               		realip_list=$last_split_ips
		else
			echo "Invalid IP"
		fi
	fi
		
	sh $path/scripts/keepalived_install.sh "$vip_list" "$port_list" "$realip_list" "$lvs_type" "$bind_inter" "$lvs_priority" "$lvs_algo"
}

#-----------------------------------------------------------------------------------
#这个是更新zabbix脚本的命令,把更新目录位于/usr/local/src/zb_update目录下
function zb_update(){
	read -p "Please Input zabbix server host's name or host's ip(eg:slave14):" hostip
        srcpath="/usr/local/src/zabbix_update"
        dstpath="/usr/local/zabbix"
        user="zabbix"
        passwd="zabbixpass"
        mysql_cmd="mysql -B -u$user -p$passwd -h$hostip zabbix -e"
        sql="select host from hosts where available=1"
        clients=`$mysql_cmd "$sql"|grep -v 'host'`
        for ip in $clients
        do
                echo "----------update files to $ip------------"
                rsync -av $srcpath/scripts/* $ip:$dstpath/scripts
                rsync -av $srcpath/configure/* $ip:$dstpath/etc/zabbix_agentd.conf.d
                service zabbix_agent restart
        done
}
#-----------------------------------------------------------------------------------
#停用磁盘的写入监测，方便hadoop的更新
function stop_disk_monitor(){
	read -p "Please input stop or start:" tag
	dbip=`cat /homed/config_comm.xml  | grep 'mt_mainsrv_ip' | awk -F '[><]' '{print $3}'`
	user="zabbix"
	passwd="zabbixpass"
	db="zabbix"
	mysql_cmd="mysql -B -u$user -p$passwd -h$dbip $db -e"
	stop_sql="update items set status=1 where key_ like "disk.resource[%,disk_status]" and status=0"
	start_sql="update items set status=0 where key_ like "disk.resource[%,disk_status]" and status=1"
	if [ "$tag" == "stop" ];then
		echo "----$dbip-----"
		stop_result=`$mysql_cmd "$stop_sql"`
		[[ $? -eq 0 ]] && echo "SUCCESS" || echo "Failed"
	elif [ "$tag" == "start" ];then
		echo "----$dbip-----"
		start_result=`$mysql_cmd "$start_sql"`
		[[ $? -eq 0 ]] && echo "SUCCESS" || echo "Failed"
	else 
		echo "Errors!your should input stop or start"
		exit
	fi
}
#-----------------------------------------------------------------------------------
#Menu
function menu(){
echo "###################################################"
echo "#                   Instructions                  #"
echo "#   1: Install PHP Mysql Apache                   #"
echo "#   2: Install Zabbix Server                      #"
echo "#   3: Install Zabbix Agent                       #"
echo "#   4: Contral Zabbix Agent                       #"
echo "#   5: Update scripts for zabbix                  #"
echo "#   6: Synchronous Files                          #"
echo "#   7: Put or Get files from FTP                  #"
echo "#   8: Keepalive LVS configure                    #"
echo "#   9: Stop or Start write file to disk           #"
echo "#  10: Install DHCP FTP NFS                       #"
echo "#  11: Exit                                       #"
echo "###################################################"
PS3="Please Choise One Number:"
select input in "Install Some soft" "Install Zabbix Server" "Install Zabbix Agent" "Contral Zabbix Agent" "Update zabbix scripts" "Synchronous Files" "FTP" "Keepalive LVS" "Crontral Disk Write Monitor" "Install some server" "Exit"
do
case $input in
	"Install Some soft")
		Install_soft
		;;
	"Install Zabbix Server")
		ZB_server
		;;
	"Install Zabbix Agent")
		ZB_agent
		;;
	"Contral Zabbix Agent")
		contral_agent
		;;
	"Update zabbix scripts")
		zb_update
		;;
	"Synchronous Files")
		Sync
		;;
	"FTP")
		ftp
		;;
	"Keepalive LVS")
		LVS
		;;
	"Crontral Disk Write Monitor")
		stop_disk_monitor
		;;
	"Install some server")
		install_dhcp_ftp_nfs
		;;
	"Exit")
		exit
		;;
esac
done
}
menu
