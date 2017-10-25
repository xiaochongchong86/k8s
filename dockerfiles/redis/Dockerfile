FROM kub01.news.bjyt.a.com:5000/centos:6.6
#安装redis 和ruby 依赖的基础类库
RUN  yum install -y gcc make openssl openssl-devel zlib zlib-devel readline-devel  dbm dbm-devel gdbm gdbm-devel
COPY redis-4.0.2   /data/redis
COPY ruby-2.2.7   /data/ruby-2.2.7
COPY rubygems-2.6.14  /data/rubygems-2.6.14
#安装ruby
RUN  cd /data/ruby-2.2.7 \
     &&  ./configure && make && make install
#解决ssl问题 在makefile中添加top_srcdir = /data/ruby-2.2.7
RUN  cd /data/ruby-2.2.7/ext/openssl/ && ruby extconf.rb
COPY Makefile  /data/ruby-2.2.7/ext/openssl/Makefile
RUN  cd /data/ruby-2.2.7/ext/openssl/ && make && make install 
#安装gem 据说1.9以后都在ruby包里面带了 所以这步可以省略
RUN  cd /data/rubygems-2.6.14 \
     &&  ruby setup.rb
RUN  cd /data/redis \
     &&  make && make install
#安装官方cluster管理工具的ruby 客户端
RUN  gem install redis
