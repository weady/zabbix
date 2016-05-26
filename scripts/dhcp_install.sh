#!/bin/bash
#
#	write by xums
#	5/10 2016

ip_range="$1"
gw="$2"
dns="$3"
pname="dhcp"
dhcp_conf="/etc/dhcp/dhcpd.conf"
start_ip=""
end_ip=""
st_range=[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}-[0-9]\{1,3\}
ip_head=""

# split ip and check ip
function checkIps(){
	if [[ $ip_range  =~ $st_range  ]];then
		ipRangeSplit
	else
		echo "invalid ip"
		exit 1
	fi
}

function ipRangeSplit(){
	start_ip=${ip_range%-*}
	ip_head=${ip_range%.*}
	local tmp_args=""
	tmp_args=${ip_range#*-}
	end_ip=$ip_head.$tmp_args
}

# check env
function checkEnv(){
	checkIps
	echo step checkEnv
	if rpm -q $pname &>/dev/null ; then
		echo $pname already installed	
	else
		installProgram
	fi
}

# install nfs-utils and rpcbind
function installProgram(){
	echo "step install $pname1"
	yum install -y $pname &>/dev/null && echo step install $pname success
	
}

# edit configuration 
function editConf(){
	echo step editconfig
	mkdir -p ${dhcp_conf%/*} &> /dev/null
	if [ -f $dhcp_conf ];then
		mv $dhcp_conf $dhcp_conf.bak && echo "$dhcp_conf be move on $dhcp_conf.bak"
	fi
	touch $dhcp_conf
	cat <<EOF >$dhcp_conf
subnet $ip_head.0 netmask 255.255.255.0 {
  range $start_ip $end_ip;
  option domain-name-servers $dns;
  option routers $gw;
  option broadcast-address $ip_head.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

}

# make directory

# start service
function startSrv(){
	chkconfig ${pname}d on 
	service ${pname}d start &>/dev/null && echo step 'startSrv success'
}
if [ ! $# -eq 3 ];then
	echo "useage like: ./$0 192.168.1.100-200  gatewayIP  dnsIP"    
	exit 1
fi
checkEnv
editConf
startSrv	
