#!/bin/bash
#
#The script used to install zabbix server
#	by wangdd 2015/10/30
#

#Install PHP
function install_php(){
	echo "Installing Dependent Packages,Please wait....."
	yum install -y gcc libjpeg libjpeg-devel net-snmp-devel curl-devel perl-DBI php-gd php-mysql php-bcmath php-mbstring php-xm gettext gdb libpng libpng-devel freetype freetype-devel libgpeg gd-devel >/dev/null
	cd /usr/local/src
	tar zxvf php.tgz >/dev/null
	[[ ! -d "/usr/local/libxml2" ]] && install_libxml
	cd /usr/local/src/php
	tar zxvf php-5.5.7.tar.gz >/dev/null
	cd php-5.5.7
	./configure --prefix=/usr/local/php \
	--with-apxs2=/usr/local/apache/bin/apxs \
	--with-libxml-dir=/usr/local/libxml2 \
	--enable-sockets \
	--with-mysql=mysqlnd \
	--with-mysqli \
	--with-gettext=/usr/lib64 \
	--enable-bcmath \
	--enable-mbstring \
 	--with-png-dir=/usr/lib64    \
	--with-jpeg-dir=/usr/lib64 \
	--with-freetype-dir=/usr/lib64 \
	--with-gd
	make && make install
	check_ok "php"
}
function check_ok(){
	if [ $? -eq 0 ];then
		echo "$1 install success"
	else
		echo "$1 install failed"
		exit 1
	fi
}

#install gd
function install_gd(){
	cd /usr/local/src
	tar zxvf libgd-gd-2.1.1.tar.gz >/dev/null
	cd libgd-gd-2.1.1
	./configure --prefix=/usr/local/gd
	make && make install  
	check_ok "gd"
}
#install libxml
function install_libxml(){
	cd /usr/local/src/php
	tar zxvf libxml2-2.7.2.tar.gz
	cd libxml2-2.7.2
	./configure --prefix=/usr/local/libxml2
	make && make install
	check_ok "libxml"
}
#main
install_php
if [ $? -eq 0 ];then
	rm -rf /usr/local/src/php_install.sh
	rm -rf /usr/local/src/php
fi
