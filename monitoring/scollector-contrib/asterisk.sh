#!/bin/bash
while true
do
        ts=$(date +%s)
        callcount=$(asterisk -rx "core show calls")
        currentcalls=$(echo $callcount | awk '{print $1}')
        totalcalls=$(echo $callcount | awk '{print $4}')
        echo "asterisk.current_calls $ts $currentcalls"
        echo "asterisk.total_calls $ts $totalcalls"
        sleep 15
done
