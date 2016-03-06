#!/bin/bash
#
#This script used get someone process memory value from `top`
#
#	wangdd 2015/10/15
#
#

sum=0
sum1=0
function mem(){
file=`top -bn 1 |tail -n +8 | awk '{print $6,$NF}' | grep "$1\>"`
value=`echo "$file" | awk '{print $1}'`
for val in $value
do
	if [[ "$val" =~ m$ ]];then
		num=`echo "$val" | sed 's/[a-z]*//g'`
		tmp=`echo "$num*1024" | bc`
		sum=`echo "$sum+$tmp" | bc`
	elif [[ "$val" =~ g$ ]];then
		num=`echo "$val" | sed 's/[a-z]*//g'`
		tmp=`echo "$num*1024*1024" | bc`
		sum=`echo "$sum+$tmp" | bc`
	elif [[ "$val" =~ [0-9]$ ]];then
		num=`echo "$val" | sed 's/[a-z]*//g'`
		tmp=`echo "$num" | bc`
		sum1=`echo "$sum+$tmp" | bc`
		
	fi
done
echo "$sum +$sum1" | bc
}

function cpu(){
	file=`top -bn 1 |tail -n +8 | awk '{print $9,$NF}' | grep "$1\>"`
	value=`echo "$file" | awk '{print $1}'`
	for val in $value
	do
		sum=`echo "scale=2;$val+$sum" | bc`
	done
echo $sum
	
}

function pmem(){
	file=`top -bn 1 |tail -n +8 | awk '{print $10,$NF}' | grep "$1\>"`
	value=`echo "$file" | awk '{print $1}'`
	for val in $value
	do
		sum=`echo "scale=2;$val+$sum" | bc`
	done
echo $sum
	
}
#
case $2 in
	mem)
		mem $1
		;;
	pmem)
		pmem $1
		;;
	cpu)
		cpu $1
		;;
	*)
		echo "Error input:"
		exit
		;;
esac
