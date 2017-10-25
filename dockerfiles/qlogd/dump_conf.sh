#!/bin/bash

while true
do
idc=`echo $MY_NODE_NAME|awk -F '.' '{print $3}'`
if [ -z $idc ]
then 
   idc=bjyt
fi
/home/s/apps/qlogd/bin/dump_conf.sh news $idc
sleep 600
done
