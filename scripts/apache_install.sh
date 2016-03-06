#!/bin/bash
#
#The script used to install apache
#
# 	by wangdd 2015/11/3
#
#

path="/usr/local/apache"
soft_path="/usr/local/src"
#
echo "--------------------------------------------------"
echo "	1:Source code install (eg:./configure ......)"
echo "	2:Binary package,does not need  install" 
echo "--------------------------------------------------"
#binary_install apache
function binary_install(){
	if [ -d "$path" ];then
		echo "Apache is installed $path"
		exit
	else
		cd $soft_path
		tar zxvf apache.tar.gz -C /usr/local/>/dev/null
		modify_config
	fi
	
}
#source install apache
function source_install(){
	if [ -d "$path" ];then
                echo "Apache is installed $path"
        else
		yum install -y -q apr apr-util pcre zlib zlib-devel openssl openssl-devel
		check_soft
		cd $soft_path
		tar zxvf httpd-2.2.22-source.tar.gz > /dev/null
		cd httpd-2.2.22
		./configure --prefix=/usr/local/apache \
		--enable-so \
		--enable-vhost-alias \
		--enable-cgi --enable-ssl \
		--enable-proxy \
		--enable-proxy-ftp \
		--enable-proxy-http \
		#--with-apr=/usr/local/apr \
		#--with-apr-util=/usr/local/apr-util \
		#--with-pcre=/usr/local/pcre \
		#--with-z=/usr/local/zlib \
		--enable-rewrite \
		--enable-ssl
		make && make install
		[[ $? -eq 0 ]] && modify_config
		rm -rf ${soft_path}/httpd-2.2.22
	fi
}
#check soft
function check_soft(){
	soft_list="apr apr-util pcre zlib zlib-devel openssl openssl-devel"
	for soft in ${soft_list}
	do
		result=`rpm -qa | grep "^${soft}-[0-9]"`
		if [ -z "$result" ];then
			echo "$soft not installed"
			exit
		else
			echo "ok"
		fi
	done
}
# modify config
function modify_config(){
	cp /usr/local/apache/bin/apachectl /etc/init.d/httpd
	chmod +x /etc/init.d/httpd
	echo "export PATH=$PATH:/usr/local/apache/bin" >>/etc/profile
}
#main
read -p "Input Your Choise(source or binary):"method
case $method in
	source)
		source_install
		;;
	binary)
		binary_install
		[[ $? -eq 0 ]] && echo "ok"
		;;
	*)
		echo "ERROR"
		;;
esac
rm -f $0
