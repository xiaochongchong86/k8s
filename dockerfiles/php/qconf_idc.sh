#!/bin/sh

idc=`echo $MY_NODE_NAME|awk -F '.' '{print $3}'`

if [ -z $idc ]
then
   idc=bjdt
fi


if grep $idc /home/q/system/qconf-agent/conf/agent.conf; then echo "Set idc to $idc."; else echo "Wrong idc $idc."; fi

echo $idc > /home/q/system/qconf-agent/conf/localidc
