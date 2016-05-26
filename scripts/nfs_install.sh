#!/bin/bash
#
#	write by xums
#	5/10 2016

storage_path="$1"
ips="$2"
pname1="nfs"
pname2="rpcbind"

# check env
function checkEnv(){
	echo step checkEnv
	if rpm -q $pname1-utils &>/dev/null ; then
		echo $pname1 already installed	
	else
		installProgram
	fi
}

# install nfs-utils and rpcbind
function installProgram(){
	yum install -y $pname2 &>/dev/null &>/dev/null && echo step $pname2 success
	echo "step install $pname1"
	yum install -y $pname1-utils &>/dev/null && echo step install $pname1 success
	
}

# edit configuration 
function editConf(){
	echo step editconfig
	if [ -f /etc/exports ];then
		mv /etc/exports /etc/exports.bak && echo "/etc/exports be move on /etc/exports.bak"
	fi
	touch /etc/exports
	echo "$storage_path   $ips(ro)" >> /etc/exports
}

# make directory
function mkdirPath(){
	echo "step mkdir $storage_path"
	if [ -d $storage_path ];then
		mv $storage_path $storage_path-bak &>/dev/null && echo "$storage_path be move on $storage_path-bak"
	fi
		mkdir $storage_path
}

# start service
function startSrv(){
	chkconfig $pname1 on 
	chkconfig $pname2 on
	service $pname2 start &>/dev/null
	service $pname1 start &>/dev/null && echo step 'startSrv success'
}
if [ ! $# -eq 2 ];then
	echo "useage like: ./$0 /xxx/xxx  ips"    
	echo "ips like: 192.168.0.0/16"
	exit 1
fi
mkdirPath
checkEnv
editConf
startSrv	
