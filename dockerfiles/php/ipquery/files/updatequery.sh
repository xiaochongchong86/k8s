#!/bin/bash

md5=`curl -s http://api.ip.360.cn/deploy/source_file/standard.md5.txt`
#echo $md5

localmd5=`md5sum /home/q/share/ipquery/ip_standard.txt |awk '{print $1}'`
#echo $localmd5

if [ $md5 == $localmd5 ]
then
   echo 'same'
   exit
else
   curl -o /home/q/share/ipquery/ip_standard.txt_new 'http://api.ip.360.cn/file/ip_standard.txt'
   newmd5=`md5sum /home/q/share/ipquery/ip_standard.txt_new|awk '{print $1}'`
   if [ $md5 == $newmd5 ]
   then
       rm -rf  /home/q/share/ipquery/ip_standard.txt
       mv  /home/q/share/ipquery/ip_standard.txt_new /home/q/share/ipquery/ip_standard.txt
       /usr/local/bin/data_renew  -p /home/s/apps/php-5.4.25/etc/include/ipquery.ini
   fi
fi

