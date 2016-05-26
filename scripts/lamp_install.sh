#!/bin/bash
#
#	by wangdd 2016/05/25
#
#
targ=$2
name=`hostname`
path="/usr/local/src"
#----------------------------------------------------
#
function clean(){
	soft_name=$1
	if [ ! "$name" == "master" -a "$targ" == "remote" ];then
		rm -f $path/lamp_install.sh
		rm -f $path/$soft_name
	fi
}
#----------------------------------------------------
function install_apache(){
	port=`netstat -unltp | grep ':80\>'`
	apache_path="/usr/local/apache"
	if [ -n "$port" -o -d "$apache_path" ];then
		echo "Apache have installed"
	else
		echo "Starting Install Apache-2.2.21,Please waiting....."
		cd $path
                tar zxvf apache-2.2.21-green.tar.gz -C /usr/local/ >/dev/null
                [[ ! -d "/var/www/html" ]] && mkdir -p /var/www/html
                /usr/local/apache/bin/httpd -k start && echo 'start httpd success'
		aut_start=`cat /etc/rc.local | grep '/usr/local/apache/'`
		[[ -z "$aut_start" ]] && echo "/usr/local/apache/bin/httpd -k start" >>/etc/rc.local
	fi
}
#----------------------------------------------------
#
function install_php(){
	php_path="/usr/local/php"
	if [ -d "$php_path" ];then
		echo "PHP have installed"
	else
		echo "Starting Install PHP-5.5.7,Please waiting....."
		cd $path
                tar zxvf php-5.5.7-green.tar.gz -C /usr/local/ >/dev/null
		[[ $? -eq 0 ]] && echo "PHP install sucess"
	fi
}
#----------------------------------------------------
#
function install_mysql(){
	port=`netstat -unltp | grep 3306`
	mysql_path="/r2/mysqldata"
	if [ ! -z "$port" -o -d "$mysql_path" ];then
		echo "mysql have installed"
	else
		echo "Starting Install Mysql-5.5.33,Please waiting....."
		cd $path
                tar zxvf mysql-5.5.33-green.tar.gz -C /usr/local/ >/dev/null
                [ -f /etc/my.cnf  ] && mv /etc/my.cnf /etc/my.cnf.bak
                \cp /usr/local/mysql/my.cnf /etc/
                if [ -d /r2/mysqldata ];then
                   echo "--/r2/mysqldata exist,it will backup on /r2/mysqldata_back--"
                   if cp -r  /r2/mysqldata /r2/mysqldata_back &>/dev/null ;then
                         rm -rf /r2/mysqldata
                   fi
                fi
                mkdir /r2/mysqldata -pv &>/dev/null
                chown -R mysql:mysql /r2/mysqldata
                /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/r2/mysqldata &>/dev/null
                \cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
                service mysqld start >/dev/null && echo "start mysql sucess"
                mysql -uroot -e "SET PASSWORD = PASSWORD('123456');drop database test"
		auto_start=`cat /etc/rc.local | grep 'service mysqld start'`
		[[ -z "$auto_start" ]] && echo "service mysqld start" >> /etc/rc.local
	fi
}
#----------------------------------------------------
case $1 in
        'apache')
		install_apache
		clean "apache-2.2.22.tar.gz"
	        ;;
        'php')
		install_php
		clean "php-5.5.7.tar.gz"
	        ;;
        'mysql')
		install_mysql
		clean "mysql-5.5.33.tar.gz"
	        ;;
	*)
		echo "Usage:$0 {apache|php|mysql}"
		;;
esac
