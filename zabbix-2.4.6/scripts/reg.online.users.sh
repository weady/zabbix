#!/bin/bash 
#
#	by wangdd 2016/04/13
#
#这个脚本主要是监测集群中的实时在线用户数和注册总数、新增用户总数

#------------------------------------------------------------------------
#获取集群中的实时在线用户数
#med_maintain库中的t_dss_stat_connectc_total_iusm表中获取的
#这张表有三个字段,源数据是homed的iusm服务每10分钟写入一次
#f_time 记录时间
#f_device_num 设备連接數
#f_user_num 用戶上线数
#需要的是f_user_num这个字段

function get_online_num(){
        host=`cat /homed/config_comm.xml  | grep 'mt_db_ip' | awk -F '[><]' '{print $3}'`
        user='root'
        passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
        database='homed_maintain'
        mysqlcmd="mysql -B -u$user -p$passwd -h$host $database"
        sql="select f_user_num from t_dss_stat_connectc_total_iusm order by f_time desc limit 1;"
        tmp=`$mysqlcmd -e "$sql"`
        online_num=`echo "$tmp" | sed 's/ /\n/g' | grep -v 'f_user_num'`
        if [ -z $online_num ];then
                online_num=0
        fi
        echo $online_num
}

#------------------------------------------------------------------------
#用户注册数从homed_iusm数据库中查询的
#直接从homed_iusm的home_info表中查询即可,home_info依家庭为主，account_info以用户为主，一个家庭可以有多个用户
#统计时候以家庭为单位，所以从home_info表中获取数据
#注册用户总数:从home_info直接查询status=1的所有用户，status=9是所有注销的用户
#日注册用户数:从account_token表中获取f_create_time字段判断账号的激活，即账号的首次登录进而统计一天的注册用户数

function get_register_num(){
        target=$1
        date_time=`date +%Y-%m-%d`
        host=`cat /homed/allips.sh | grep "export iusm_mysql_ips" | awk '{print $NF}' | tr -d '"'`
        user="root"
        passwd=`cat /homed/config_comm.xml  | grep 'mt_db_pwd' | awk -F '[><]' '{print $3}'`
        database="homed_iusm"
        mysqlcmd="mysql -B -u$user -p$passwd -h$host $database"
        sum_num_sql="select count(*) from home_info where status=1;"
        day_num_sql="select count(*) from account_token where f_create_time like '"${date_time}%"';"
        if [ $target == "sum" ];then
                sum_num=`$mysqlcmd -e "$sum_num_sql" | sed 's/ /\n/g' | grep -v "count"`
                if [ -z $sum_num ];then
                        sum_num=0
                 fi
                echo $sum_num
        elif [ $target == "day" ];then
                day_num=`$mysqlcmd -e "$day_num_sql" | sed 's/ /\n/g' | grep -v "count"`
                if [ -z $day_num ];then
                        day_num=0
                fi
                echo $day_num
        fi
}

#------------------------------------------------------------------------
#主入口
case $1 in
	homed_online_num)
                get_online_num
                ;;
        register_sum_num)
                get_register_num "sum"
                ;;
        register_day_num)
                get_register_num "day"
                ;;
        *)
                echo "Error"
                exit
esac

