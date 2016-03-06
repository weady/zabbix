#!/bin/bash
#
#The script used to install zabbix server
#	by wangdd 2015/10/30
#


#check env function
#
#dbip=`cat /homed/config_comm.xml | grep "mt_db_ip" |sed -re 's/.*>(.*)<.*$/\1/g'`
dbip="127.0.0.1"
username=$3
password=$4
z_server=$1
z_name=`hostname`
function check(){
php_soft="/usr/local/php/bin"
httpd_proc=`ps -ef | grep httpd | grep -v grep`
httpd_soft="/usr/local/apache/bin"
default_data="/var/lib/mysql"
rpm_mysql=`rpm -qa | grep "mysql-server"`
mysql_pro=`ps -ef | grep mysql | grep -v grep`
mysql_file="/etc/my.cnf"
mysql_db=`cd ${default_data} && find ./ -mindepth 1 -type d | egrep -v "mysql|test"`
zb_server=`ps -ef | grep zabbix_server | grep -v grep`
zb_conf="/usr/local/zabbix/etc/zabbix_server.conf"
[[ -n "$zb_server" || -f "$zb_conf" ]] && echo "zabbix server installed" && clean 
	if [ -d "${php_soft}" ];then
		echo "php installed"
       	else
                echo -e "\033[40;31m php not installed \033[0m"
		clean
	fi
        if [ -d "${httpd_soft}" -o -n "$proc" ];then
                echo "apache installed"
        else
                echo -e "\033[40;31m apache not installed \033[0m"
		clean
        fi
	if [ -n "$rpm_mysql" -o -n "$mysql_pro" -o "$mysql_db" -o -f "$mysql_file" ];then
       	 	echo "mysql installed" 
	else
        	echo -e "\033[40;31m mysql not installed \033[0m" 
		clean
	fi
}
#Install server
function ZB_server(){
	yum install -y -q --skip-broken gcc mysql-devel net-snmp-devel net-snmp-utils php-gd php-mysqlphp-common php-bcmath php-mbstring php-xml curl-devel iksemel* OpenIPMIOpenIPMI-devel fping libssh2 libssh2-devel unixODBC unixODBC-develmysql-connector-odbc openldap openldap-devel java java-devel >/dev/null
	mysql_pro=`ps -ef | grep mysql | grep -v grep`
	if [ -n "$mysql_pro" ];then
	mysql -u$username -p$password -h$dbip -e "use mysql;delete from user where user='';flush privileges;" 
	mysql -u$username -p$password -h$dbip -e "GRANT CREATE,DROP,ALTER,INSERT,DELETE,UPDATE,SELECT ON accesslog.* TO zabbix@'%' IDENTIFIED BY 'zabbixpass';"
	mysql -u$username -p$password -h$dbip -e "create database if not exists zabbix character set utf8;grant all on zabbix.* to zabbix@'%' identified by 'zabbixpass';flush privileges;"
	[[ $? -eq 0 ]] && echo "Zabbix database create sucess" || clean
	else
		echo "mysql not running"
		clean
	fi
	[[ -z `id zabbix` ]] && useradd -s /sbin/nologin zabbix >/dev/null 2>&1
	cd /usr/local/src/zabbix-2.4.6
	autoreconf -ivf
	mysql -uzabbix -pzabbixpass -h$dbip zabbix <./mysql/zabbix_init.sql >/dev/null
	[[ $? -ne 0 ]] && echo "init zabbix database failed" && clean
	./configure \
	--prefix=/usr/local/zabbix \
	--with-mysql \
	--with-net-snmp \
	--with-libcurl \
	--enable-server \
	--enable-agent \
	--enable-proxy
	make && make install
		if [ $? -eq 0 ];then
			echo "zabbix install sucess"
			\cp -a /usr/local/src/zabbix-2.4.6/scripts /usr/local/zabbix
			\cp -a /usr/local/zabbix/scripts/zabbix_server /etc/init.d/zabbix_server
			\cp -a /usr/local/zabbix/scripts/zabbix_agent /etc/init.d/zabbix_agent
			\cp -a /usr/local/src/zabbix-2.4.6/conf/* /usr/local/zabbix/etc
			rm -rf /usr/local/zabbix/etc/zabbix_agent.conf* 
			rm -rf /usr/local/zabbix/etc/zabbix_proxy.conf* 
			rm -rf /usr/local/zabbix/etc/zabbix_agentd.win.conf
			sed -i "s/192.168.52.214/$z_server/" /usr/local/zabbix/etc/zabbix_server.conf
			sed -i "s/zabbixserip/$z_server/g" /usr/local/zabbix/etc/zabbix_agentd.conf
			sed -i "s/zabbixagentip/$z_name/" /usr/local/zabbix/etc/zabbix_agentd.conf
			mv /usr/local/php/lib/php.ini	/usr/local/php/lib/php.ini.bak >/dev/null 2>&1
			\cp -a /usr/local/src/zabbix-2.4.6/conf/php.ini	/usr/local/php/lib
			\cp -a /usr/local/src/zabbix-2.4.6/web/zabbix	/var/www
			sed -i "s/192.168.102.230/$z_server/" /var/www/zabbix/conf/zabbix.conf.php
			service zabbix_server start
			service zabbix_agent start
		else
			echo "zabbix install failed"
			clean
		fi
}
#install mailx
function mailx_install(){
	mail=`rpm -qa | grep "^mailx-"`
	smtp=`grep "smtp-auth-user" /etc/mail.rc`	
	if [ -z "mail" -o -z "$smtp" ];then
		yum install -y mailx
cat >>/etc/mail.rc <<EOF
set from=wangdd@iPanel.cn smtp=smtp.iPanel.cn
set smtp-auth-user=wangdd smtp-auth-password=xxxx
set smtp-auth=login
EOF
	fi
}
#clean
function clean(){
	rm -rf /usr/local/src/zabbix-2.4.6
	rm -f /usr/local/src/agent_install.sh
	rm -f /usr/local/src/server_install.sh
	rm -f /usr/local/src/zabbix_contral.sh
	rm -rf /usr/local/src/scripts
	exit
}
function optimize_mysql(){
#数据库分区,分区的sql语句在/usr/local/zabbix/scripts/zabbix.partition.sql
#day--->NOWDAY;nday--->NEXTDAY;ndayt--->NEXTDAYT
#mon--->NOWMON;nmon--->NEXTMON;nmont--->NEXTMONT
#
#

#当前月NOWMON----mon
#下个月NEXTMON---nmon
#下个月-:ZZZM----za
#下下个月-:BBZZ---zb
#当前日NOWDAY----day
#下一天NEXTDAY---nday
#下一天-:ZBBD---zc
#下下一天-:TZZ---zd

day=`date +%Y%m%d`
nday=`date +%Y%m%d -d '+1 days'`
zc=`date +%Y-%m-%d -d '+1 days'`
zd=`date +%Y-%m-%d -d '+2 days'`
mon=`date +%Y%m`
nmon=`date +%Y%m -d '+1 month'`
za=`date +%Y-%m -d '+1 month'`
zb=`date +%Y-%m -d '+2 month'`
tmon=`date +%Y%m -d '+2 month'`
sed -i "s/NOWDAY/$day/g;s/NEXTDAY/$nday/g;s/ZBBD/$zc/g;s/TZZ/$zd/g" /usr/local/zabbix/scripts/zabbix.partition.sql
sed -i "s/NOWMON/$mon/g;s/NEXTMON/$nmon/g;s/ZZZM/$za/g;s/BBZZ/$zb/g" /usr/local/zabbix/scripts/zabbix.partition.sql
mysql -uzabbix -pzabbixpass zabbix </usr/local/zabbix/scripts/zabbix.partition.sql >/dev/null 2>&1
mysql -uzabbix -pzabbixpass zabbix </usr/local/zabbix/scripts/zabbix.auto.partition.sql >/dev/null 2>&1
echo "1 0 * * * /usr/local/zabbix/scripts/auto.partition.sh >/dev/null" >> /var/spool/cron/root 
}
function modify_power(){
chmod u+w /etc/sudoers
sed -i "s/Defaults    requiretty/Defaults    \!requiretty/" /etc/sudoers
cat >>/etc/sudoers <<EOF
Cmnd_Alias MONITORING = /bin/netstat,/sbin/sudo,/bin/*,/sbin/*,/opt/MegaRAID/MegaCli/MegaCli64
zabbix        ALL=(root) NOPASSWD:MONITORING
EOF
chmod u-w /etc/sudoers
}
#main
function main(){
check
if [ $? -eq 0 ];then
	ZB_server
	optimize_mysql
fi
}
main
