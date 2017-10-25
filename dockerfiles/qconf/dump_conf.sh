#!/bin/bash

while true
do
idc=`echo $MY_NODE_NAME|awk -F '.' '{print $3}'`
if [ -z $idc ]
then 
   idc=bjyt
fi

cd /home/infra/qbus/agent/monitor && ./monitor_hermes_agent.sh
sleep 60
done

