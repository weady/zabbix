#!/bin/bash
#
#This script used to send alarm SMS
#
#       by liumz 2015/12/14
#
#msgContent=`echo "$3" |iconv -f utf-8 -t gbk`
msgContent=$3
echo $msgContent >> /tmp/smsSend.log
wget "http://access.homed.me/sms/sms_send?recvmode=0&receiver=$1&msg=$msgContent&st=1&smsauth=aaa:abc12345" -O /tmp/smsSendResponseTmp &
