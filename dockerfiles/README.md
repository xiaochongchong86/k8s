守护方式 supervisor

conf
    dump_conf.sh    dump 配置文件 
    entrypoint.sh   qconf 守护进程
qlog
   dump_conf.sh  将cron 改成进程每10分钟dump一次
   entrypoint.sh 将qlog 改成前台运行
