FROM kub01.news.bjyt.a.com:5000/centos:6.6

RUN rm -rf /etc/yum.repos.d/*
COPY repos/* /etc/yum.repos.d/
COPY qlogd_centos6.2.1.52   /home/s/apps/qlogd
RUN yum install -y xz
RUN yum install -y supervisor
RUN mkdir -p /home/s/var/log/default_qlog/ \
    && mkdir -p /home/s/apps/qlogd/log/qlogd_misslog \
    && mkdir -p /home/s/apps/qlogd/log/qbus2_log \
    && mkdir -p /home/s/var/run \
    && ln -sf /home/s/apps/qlogd/lib/libqlogd.so.2.1.22 /home/s/apps/qlogd/lib/libqlogd.so.2 
RUN  yum clean all \
    &&yum localinstall -y   /home/s/apps/qlogd/rpm/*.rpm

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD dump_conf.sh /dump_conf.sh
RUN chmod +x /dump_conf.sh

ADD supervisord.conf  /etc/
CMD ["supervisord", "-n"]
