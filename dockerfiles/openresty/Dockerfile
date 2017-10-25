FROM kub01.news.bjyt.a.com:5000/centos:6.6
RUN  rpm --rebuilddb 
RUN  yum install -y \
         readline-devel \
         pcre-devel \
         openssl-devel \
         gcc \
         curl \
         perl
COPY openresty-1.11.2.2  /tmp/openresty-1.11.2.2
WORKDIR /tmp/openresty-1.11.2.2
RUN  ./configure    --prefix=/home/s/apps/openresty  --with-stream  --with-stream=dynamic

RUN  gmake
RUN  gmake install
RUN  ln -sf /home/s/apps/openresty/nginx  /home/s/apps/nginx


