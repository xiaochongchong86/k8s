#!/usr/bin/env bash

path='/home/s/apps/qlogd'

export MY_NODE_NAME=kub02.news.bjyt.a.com

business_type=news
idc=`echo $MY_NODE_NAME|awk -F '.' '{print $3}'`

if [ -z $idc ]
then 
   idc=bjyt
fi

name=$business_type-$idc

if [ ! -f $path/etc/$name.conf ]; then
    cp $path/etc/logconfig.conf $path/etc/$name.conf
fi

mkdir -p /home/s/var/run/qlogd/

if [ ! -s /home/s/var/run/qlogd/${name}.pid ] ; then
        rm -f /home/s/var/run/qlogd/${name}.pid
fi

mkdir -p /home/s/apps/qlogd/log/qlogd_misslog

$path/bin/qlogd -f  -n $name \
                --cfg-dir=$path/etc \
                --log-dir=$path/log/

