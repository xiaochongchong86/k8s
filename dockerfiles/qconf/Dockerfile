FROM kub01.news.bjyt.a.com:5000/centos:6.6


RUN rm -rf /etc/yum.repos.d/*
COPY repos/* /etc/yum.repos.d/
RUN  useradd  infra 
RUN  yum clean all
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

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD dump_conf.sh /dump_conf.sh
RUN chmod +x /dump_conf.sh

ADD supervisord.conf  /etc/
CMD ["/usr/bin/supervisord", "-n"]

