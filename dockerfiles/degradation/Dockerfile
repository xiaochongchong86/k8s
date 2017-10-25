FROM kub01.news.bjyt.a.com:5000/centos:6.6
RUN rm -rf /etc/yum.repos.d/*
COPY repos/* /etc/yum.repos.d/
RUN  mkdir -p  /home/s/apps
COPY lib  /home/s/lib
RUN   echo '/home/s/lib' > /etc/ld.so.conf.d/home_s.conf \
      && ldconfig
COPY qlogd_centos6.2.1.52   /home/s/apps/qlogd
RUN  rpm --rebuilddb  \
    &&yum localinstall -y   /home/s/apps/qlogd/rpm/*.rpm
COPY addops-libqconf-0.4.0-1.el6.x86_64.rpm  /tmp/addops-libqconf-0.4.0-1.el6.x86_64.rpm
RUN  rpm -ivh /tmp/addops-libqconf-0.4.0-1.el6.x86_64.rpm

RUN  rpm --rebuilddb \
     && yum install -y sudo xz supervisor wget
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

RUN mkdir /home/s/apps/qlogd/log/qlogd_misslog -p

COPY btime_degradation.centos6.1.0.16   /home/s/apps/degradation
WORKDIR /home/s/apps/degradation
#CMD "sh /home/s/apps/degradation/start.sh"
COPY start.sh  /start.sh
CMD "/start.sh"
