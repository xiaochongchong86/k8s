FROM kub01.news.bjyt.a.com:5000/centos:6.6
RUN  useradd s
RUN  useradd q
RUN   useradd infra 
RUN rm -rf /etc/yum.repos.d/*
COPY repos/* /etc/yum.repos.d/

RUN  rpm --rebuilddb \
     && yum install -y  uuid libuuid libuuid-devel uuid-devel libtool-ltdl-devel recode-devel libtidy-devel libicu-devel \
     gcc \
     gcc-c++ \
     autoconf \
     automake \
     libtool \
     make \
     cmake \
     glibc \
     glibc-common \
     glibc-devel \
     glibc-headers \
     libevent20 \
     libibverbs \
     libmcrypt \
     protobuf \
     wget \
     zlib \
     zlib-devel \
     openssl \
     openssl-devel \
     pcre-devel \
     libxml2 \
     libxml2-devel \
     libcurl \
     libcurl-devel \
     libpng-devel \
     libjpeg-devel \
     freetype-devel \
     libmcrypt-devel \
     openssh-server \
     libmemcached \
     libmemcached-devel \
     sudo \
     xz \
     libzookeeper \
     zookeeper-lib \
     python-setuptools && \
     yum clean all

RUN  mkdir -p /da1/s/apps \
     && ln -snf /da1/s /home/s \
     && ln -snf /home/s /home/q

COPY  php-5.4.25  /home/s/apps/php-5.4.25
RUN   ln -sf /home/s/apps/php-5.4.25  /home/s/apps/php
RUN   ln -sf /home/s/apps/php   /usr/local/php
COPY  lib         /home/s/lib
# yaf
RUN   echo '/home/s/lib' > /etc/ld.so.conf.d/home_s.conf \
      && ldconfig 
COPY  yaf/etc/yaf.ini  /home/s/etc/yaf.ini
RUN   ln -sf /home/s/apps/php/bin/php  /usr/local/bin/php

#图床
RUN   yum install -y  php54-qlog
COPY  picasso_sdk-4.0.0.0  /home/q/php/picasso_sdk-4.0.0.0
COPY  picasso_sdk-4.0.0.0  /home/s/apps/php_SDK/picasso_sdk-4.0.0.0

#qconf SDK
COPY  rpms/*  /tmp/
RUN   rpm -ivh /tmp/addops-php-sdk-Qconf-0.4.0-1.el6.x86_64.rpm 
#qbus1 client
COPY  qbus/files/qbus_sdk.sh   /tmp
RUN   bash /tmp/qbus_sdk.sh -r php   
#qbus3 client
COPY  qbus/files/qbus3.ini  /home/s/apps/php/etc/include/qbus3.ini
COPY  qbus/files/librdkafka.so.1 /home/s/lib/librdkafka.so.1
COPY  qbus/files/kafka_client3.0    /home/q/php/kafka_client3.0
#qbus2 client
COPY  qbus/files/qbus2.ini  /home/s/apps/php/etc/include/qbus2.ini
COPY  qbus/files/php/qbus   /home/q/php/qbus
COPY  qbus/files/qbus.so    /home/s/apps/php/extensions/qbus.so
#ipquery
COPY  ipquery/files/home/q/share/ipquery  /home/q/share/ipquery
COPY  ipquery/files/usr/local/bin/data_renew  /usr/local/bin/data_renew
COPY  ipquery/files/phpmod/ipquery.so   /home/s/apps/php/extensions/ipquery.so
COPY  ipquery/files/phpmod/ipquery.ini  /home/s/apps/php/etc/include/ipquery.ini
COPY  ipquery/files/ip_standard.txt_new  /home/q/share/ipquery/ip_standard.txt
#COPY  ipquery/files/updatequery.sh    /tmp
#RUN   bash /tmp/updatequery.sh

#php-fpm
RUN   mkdir /home/s/log/ \
      && ln -sf /home/s/log/  /home/s/logs \
      && mkdir -p  /home/s/var/proc 

COPY  phpfpmd   /etc/init.d/phpfpmd

#qconf client
COPY home/q /home/q
COPY data  /data
COPY usr/local/bin/qconf  /usr/local/bin/qconf
WORKDIR  /home/q/system/qconf-agent/monitor
RUN  curl qconf-conf.add.corp.a.com:8360/qconf-conf/agent.newconf > /home/q/system/qconf-agent/conf/agent.conf \
     && curl qconf-conf.add.corp.a.com:8360/qconf-conf/qconf.newconf > /home/q/system/qconf-agent/conf/qconf.conf \
     && sed -i "s#daemon_mode=1#daemon_mode=0#" /home/q/system/qconf-agent/conf/agent.conf \
     && sed -i "s#log_level=4#log_level=6#" /home/q/system/qconf-agent/conf/qconf.conf \
     && sed -i "s#daemon_mode=1#daemon_mode=0#" /home/q/system/qconf-agent/conf/qconf.conf \
     && sed -i "s#log_level=4#log_level=6#" /home/q/system/qconf-agent/conf/qconf.conf \
     && chmod +x /home/q/system/qconf-agent/bin/qconf
