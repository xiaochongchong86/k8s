#!/bin/sh
curpath=`pwd`
dir=`dirname $0`
if [ $dir == '.' ];then
    realdir="$curpath"
else
    realdir="$curpath/$dir"
fi
kafka_offset_dir="$realdir/consume_offset";
kafka_log_dir="$realdir/../logs";

mkdir -p $kafka_offset_dir
if [ -d "$kafka_offset_dir" ]; then
    echo "create $kafka_offset_dir directory ................ OK"
else
    echo "create $kafka_offset_dir directory ................ FAILED"
    exit
fi

chmod a+w $kafka_offset_dir

mkdir -p $kafka_log_dir
if [ -d "$kafka_log_dir" ]; then
    echo "create $kafka_log_dir directory ................ OK"
else
    echo "create $kafka_log_dir directory ................ FAILED"
    exit
fi

chmod a+w $kafka_log_dir



#create autoload file
/usr/local/bin/php $realdir/build_includes.php $realdir $realdir/kafka_client.php

#创建本机器默认使用的集群
#cluster=`hostname|awk -F"." '{print $3;}'`
#cluster="test"
#config_file="$realdir/Kafka/Config.php"
#zkserver=`php -r "include('$config_file');echo Kafka_Config::\\$zkClusterHosts[$cluster];"`
#if [ ${#zkserver} -ge 1 ];then
#    let num=`cat $config_file | grep 'default' | grep '=>' | wc -l`
#    if [ $num == 0 ];then
#        sed -i  "/test.*=>/a'default'=>'$zkserver'," $config_file
#    else
#        sed "s/^'default'=>.*/'default'=>'$zkserver',/" $config_file
#    fi
#fi
