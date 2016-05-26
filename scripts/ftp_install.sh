#!/bin/bash
#
#	write by xums
#	5/10 2016
storage_path=$1
pname="vsftpd"

# check Env
function checkEnv(){
	echo step checkEnv
	if rpm -q $pname &>/dev/null ; then
		echo $pname already installed
		return 0
	else
		installProgram $pname &>/dev/null
	fi
}

# install vsftpd
function installProgram(){
	echo "step install $pname"
	yum install -y $pname &>/dev/null && echo step install success
	
}

# edit configuration
function editConf(){
	echo step editconfig
	sed -i 's@anonymous_enable=YES@anonymous_enable=NO@gi'  /etc/vsftpd/vsftpd.conf 
	echo 'chroot_local_user=YES' >>  /etc/vsftpd/vsftpd.conf 
	echo 'chroot_list_enable=NO' >> /etc/vsftpd/vsftpd.conf
	echo "local_root=$storage_path" >> /etc/vsftpd/vsftpd.conf
}

# make directory 
function mkdirPath(){
	echo step useradd ipanel
	if ! id ipanel &>/dev/null ;then
		useradd -s /sbin/nologin ipanel &>/dev/null 
		echo ipanel | passwd --stdin ipanel &>/dev/null
	fi
	echo "mkdir $storage_path"
	if [ -d $storage_path ];then
		mv $storage_path $storage_path-bak &>/dev/null && echo "$storage_path be move on $storage_path-bak"
		mkdir $storage_path
	else
		mkdir $storage_path
	fi	
}

# start service
function startSrv(){
	chkconfig $pname on 
	chown ipanel.ipanel $storage_path
	service $pname start &>/dev/null && echo step startSrv success
}


if [ ! $# -eq 1 ];then
	echo "useage $0 /xxx/xxx"
	exit 1
fi
mkdirPath
checkEnv
editConf
startSrv	
