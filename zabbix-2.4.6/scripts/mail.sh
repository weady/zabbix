#!/bin/bash
#
#This script used to send alarm mail
#
#
receiver=$1
subject=$2
html=$3
dos2unix -k $html
action="http://xxxx/bottom-service/sendEmail.action"
post_text="fromEmail=boss@xxxx.cn&fromName=boss&toEmail=$receiver&toName=&subject=$subject&htmlMsg=$html"
curl -d "$post_text" "$action" &
