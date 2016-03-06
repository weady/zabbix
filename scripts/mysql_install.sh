#!/bin/bash
#
#The scritp used to install mysql
#
#
# by wangdd 2015/11/3

soft_path="/usr/local/src"
#
function check_mysql(){
default_data="/r2/mysqldata"
data_dir="/var/lib/mysql"
mysql_pro=`ps -ef | grep mysql | grep -v grep`
mysql_db=`cd ${default_data} && find ./ -mindepth 1 -type d | egrep -v "mysql|test"`
if [ -n "$mysql_pro" ];then
	echo "mysql is running"
	exit
elif [ -d "$default_data" -o -d "$data_dir" ];then
	echo "mysql installed"
	exit
fi
}
#
function install_mysql(){
cd $soft_path
tar zxvf mysql5.5.33.tgz >/dev/null
cd mysql5.5.33
rpm -ivh *.rpm --force >/dev/null
if [ $? = "0" ]
then
        cd /usr/bin
        ./mysql_install_db --user=mysql --datadir=$default_data >/dev/null
        \cp -a /usr/local/src/zabbix-2.4.6/config/my.cnf /etc/my.cnf
        setenforce=0
        chkconfig --add mysqld
        service mysqld start
        mysql -uroot -e "SET PASSWORD = PASSWORD('123456')"
else
        echo "Install Mysql Failed"
fi
}
check_mysql
install_mysql
rm -rf $soft_path/mysql5.5.33
rm -f $0
