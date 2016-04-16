#!/bin/bash
#
#这个脚本主要是统计本机的ilogslave服务号
#
#	wangdd 2016/04/07


ilogslaveid=`cat /homed/start.sh | grep "^_restart.*ilogslave.exe" | awk '{print $(NF-1)}' | tr -d "'"`
type="StbNowMovieCount PadNowMovieCount MobileNowMovieCount PadNowTSCount MobileNowKTSCount NowTRCount StbNowTSCount PcNowDCount PcNowLiveCount NowKTSCount StbNowTotalCount PadNowTotalCount MobileNowTotalCount PcNowKTSCount PcNowMovieCount NowTSCount MobileNowTRCount SmartCardNowKTSCount SmartCardNowDCount MobileNowLiveCount PcNowTotalCount StbNowDCount SmartCardNowTRCount PadNowLiveCount SmartCardNowMovieCount NowMovieCount PcNowTRCount PadNowKTSCount SmartCardNowTotalCount NowTotalCount NowLiveCount MobileNowTSCount PadNowTRCount StbNowTRCount StbNowKTSCount SmartCardNowTSCount NowDCount StbNowLiveCount PadNowDCount PcNowTSCount MobileNowDCount SmartCardNowLiveCount"
name=`echo "$type" | sed 's/ /\n/g'`
COUNT=`echo "$name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$name" | while read LINE; 
		do
    			echo -n '{"{#DEVICETYPE}":"'$ilogslaveid:$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

