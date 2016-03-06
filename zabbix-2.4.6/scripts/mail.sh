#!/bin/bash
#
#This script used to send alarm mail
#
#	by wangdd 2015/10/21
#
sender="boss@xxxx.cn"
receiver=$1
subject=$2
html=$3
dos2unix -k $html
action="http://boss.xxxx.cn/bottom-service/sendEmail.action"
post_text="fromEmail=$sender&fromName=boss&toEmail=$receiver&toName=&subject=$subject&htmlMsg=$html"
curl -d "$post_text" "$action" &
