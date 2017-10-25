#!/bin/bash
PATH="/sbin:/usr/sbin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/bin:/bin:/usr/local/bin";export PATH


# install crontab
function install_cron
{
    rm -rf /tmp/crontab3.tmp
    sudo su $2 "-c crontab -l > /tmp/crontab3.tmp" >> /dev/null 2>&1
    num=`cat /tmp/crontab3.tmp | grep 'monitor_hermes_agent.sh' | wc -l`
    if [[ $num != 0 ]];then
        echo "1|monitor crontab exists"
    fi
    echo "* * * * * (cd $1/agent/monitor && ./monitor_hermes_agent.sh >> ../log/monitor.log 2>&1)" >> /tmp/crontab3.tmp
    sudo su $2 "-c crontab /tmp/crontab3.tmp"
    rm -rf /tmp/crontab*
    #########crontab去重
    sort -k2n /var/spool/cron/$2 | uniq > /var/spool/cron/$2_bak
    rm -f /var/spool/cron/$2
    mv /var/spool/cron/$2_bak /var/spool/cron/$2
}

function install_clean_log
{
    tmp=/tmp/clean_log.tmp
    dest=$1/shells/clean_log.sh
    rm -rf $tmp
    if [ ! -f "$dest" ];then
        mkdir -p $1/shells
        echo "!#/bin/bash" >> $dest
    fi
    cat $dest >> $tmp
    num=`cat $tmp |grep -rw "$2" | wc -l`
    if [[ $num == 0 ]];then
        echo "find $2 -type f -mtime +7 -exec rm -f {} \; > /dev/null 2>&1 &" >> $dest
    fi
    chown -R $3:$3 $1/shells
    rm -rf $tmp
}

function install_config
{
    mkdir -p $1/config/ >> /dev/null 2>&1
    cd $1/config/
    if [ "x$3" == "xon" ]; then
        wget --connect-timeout=10 -Nq http://db1.baike.bjt.a.com:12585/qbus/client/config/qbus-config.tar.gz >> /dev/null 2>&1
        tar xvf qbus-config.tar.gz >> /dev/null 2>&1
    fi
    chown -R $2:$2 $1/*
    rm -f qbus-config.tar.gz
}

function escape
{
    tmp=$1
    ret=`echo $tmp| sed 's#\/#\\\/#g'`
    echo $ret
}

check_user() {
    if [ $UID -ne 0 ]; then
        echo $"Non root user. Please run as root."
        exit 1
    else
        return 0
    fi
}

function check_user_exist
{
    user=`cat /etc/passwd | grep $1`
    if [ -z $user ];then
        echo "ERROR: user $1 not exist, exit."
        exit -1
    else
        return 0
    fi
}

function check_install_dir
{
    if [[ "$2" == "" ]];then
        echo $1
        return 0
    fi
    if [[ "$1" != "$2" ]]; then
        echo $2
    else
        echo $1
    fi
}

function check_install_user
{
    if [[ "$2" == "" ]];then
        echo $1
        return 0
    fi
    if [[ "$1" != "$2" ]]; then
        echo $2
    else
        echo $1
    fi
}

function check_php_dir
{
    PHP_PATH="$1"
    if [[ $1 == "" ]];then
        PHP_PATH="/usr/local/php/bin/php"
        [ -f $PHP_PATH -a -x $PHP_PATH ] 
        REV=$?
        [ $REV -ne 0 ] && echo "please input php path!" && exit 2
        echo $PHP_PATH
    else
        [ -f $PHP_PATH -a -x $PHP_PATH ] 
        REV=$?
        [ $REV -ne 0 ] && echo "Please input correct php path! eg:/usr/local/bin/php" && exit 2
        echo $PHP_PATH
    fi
}

function mkdir_local_logs
{
    mkdir -p /home/syncops/software/kafka_agent/local_logs/ >> /dev/null 2>&1
    chmod 777 -R /home/syncops/software/kafka_agent/local_logs/ >> /dev/null 2>&1
    chmod a+x /home/syncops
    #link
    rm -rf $1/agent/local_logs
    ln -sf /home/syncops/software/kafka_agent/local_logs $1/agent/local_logs 
    chown $2:$2 -R /home/syncops/software/kafka_agent/local_logs
    chown -R $2:$2 $1/agent/local_logs
}

function transfer_user_info
{
    DATA_DIR=/home/syncops/software/kafka_agent/data
    if [ -d $DATA_DIR ];then
        cp $DATA_DIR/* $1/agent/data/
        chown $2:$2 -R $1/agent/data
        mkdir -p /tmp/qbus/bak/data
        mv $DATA_DIR /tmp/qbus/bak/data
    fi
    


    CONF_DIR=/home/syncops/software/kafka_agent/conf
    if [ -d $CONF_DIR ] ;then
        cp $CONF_DIR/* $1/agent/conf/
        chown $2:$2 -R $1/agent/conf
        mkdir -p /tmp/qbus/bak/conf
        mv $CONF_DIR /tmp/qbus/bak/conf
    fi

}

function backup_pre_agent
{
    PWD=`pwd`
    cd /home/syncops/software/kafka_agent/
    if [ ! -d backup ] ;then
        mkdir backup
    fi 
    if [ -d bin ] ;then
        mv bin backup/
    fi
    if [ -d conf ] ;then
        mv conf backup/
    fi
    if [ -d data ] ;then
        mv data backup/
    fi
    if [ -d log ] ;then
        mv log backup/
    fi
    if [ -d monitor ] ;then
        mv monitor backup/
    fi
    if [ -d tools ] ;then
        mv tools backup/
    fi
    if [ -f VERSION ] ;then
        mv VERSION backup/
    fi
    cd $PWD
}

# remove syncops and root crontab
function com_cron()
{
    if [ -f /var/spool/cron/syncops ]; then
        sed  -i "s/^\(.*kafka_agent.*\)/#\1/g" /var/spool/cron/syncops
    fi
    sed -i "/^\(.*kafka_agent.*\)/d" /var/spool/cron/root
}

function stop_pre_agent()
{
    PWD=`pwd`
    if [ -d /home/syncops/software/kafka_agent/tools/ ]; then
        cd /home/syncops/software/kafka_agent/tools/ ; sh qbus_agent_mgr.sh stop
        cd $PWD
        sleep 1
    fi

}

function check_python
{
    echo "-------- Check Python Env Start --------"
    # select python which has gdbm module
    local has_gdbm="no";
    local python_versions=('python2.6' 'python26' 'python2.7' 'python27' 'python')
    local python_v='python2.6'
    for py_v in ${python_versions[@]}
    do
        ret=`$py_v -c 'import gdbm' > /dev/null 2>&1`
        if [ $? -eq 0 ]; then has_gdbm="yes"; break; fi
    done

    if [ ${has_gdbm} == "no" ]; then
       echo -e "
all installed python versions have no gdbm module, please check python with below command.
             $ python -c \"help('modules')\" |grep gdbm
       "
       exit 1
    fi
    echo "-------- Check Python Env Done --------"
}

function install_agent
{
    mkdir -p $1/agent/local_logs/ >> /dev/null 2>&1
    chmod 777 -R $1/agent/local_logs/ >> /dev/null 2>&1
    chmod a+x /home/$2
    com_cron
    stop_pre_agent

    cd $1/agent
    if [ "x$3" == "xon" ]; then
        wget --connect-timeout=10 -Nq http://db1.baike.bjt.a.com:12585/qbus/client/agent/qbus_agent_infra.tar.gz
        tar xvf qbus_agent_infra.tar.gz >> /dev/null 2>&1
    fi
    chown -R $2:$2 $1/agent/
    DEST=`escape $1`
    cd $1/agent/monitor
    sed -i "s/\/home\/infra\/qbus/$DEST/g"  *
    cd $1/agent/tools
    sed -i "s/\/home\/infra\/qbus/$DEST/g"  *
    install_clean_log $1 $1/agent/log/ $2

    cd $1/agent
    rm -rf qbus_agent_infra.tar.gz

    mkdir_local_logs $1 $2
    transfer_user_info $1 $2

    echo "0|qbus_agent install done"
}

function install_php_sdk
{
    mkdir -p $1/client >> /dev/null 2>&1
    chmod 755 $1/client
    cd $1/client/
    wget --connect-timeout=10 -Nq http://db1.baike.bjt.a.com:12585/qbus/client/php/qbus_client_php_infra.tar.gz
    tar -xvf qbus_client_php_infra.tar.gz >> /dev/null 2>&1
    ln -sf $1/client/qbus_client_php-0.1.0 $1/client/php >> /dev/null 2>&1

    DEST=`escape $1`
    cd $1/client/php/lib
    sed -i "s/\/home\/infra\/qbus/$DEST/g"  gen_config.php

    cd $1/client/php
    sudo sh bootstrap.sh $3 >> /dev/null 2>&1
    chown $2:$2 -R $1
    
    install_clean_log $1 $1/client/php/logs/ $2

    rm -rf $1/client/qbus_client_php_infra.tar.gz
    unlink $1/client/php/qbus_client_php-0.1.0 >> /dev/null 2>&1
    zoo=`$3 -m -c $4 |grep zookeeper`
    if [ "$zoo" == "0" ];then
        echo zookeeper exits  >> /dev/null 2>&1
    else
        ver=`$3 -v 2>/dev/null |grep built |awk '{print $2}'`
        ver=${ver:0:3}
        ini_path=$4
        so_path=`cat $4 |grep extension_dir |grep -v ";" |awk -F'= ' '{print $2}' |tr -d \"`
        zoo=`cat $4 |grep zookeeper.so |wc -l`
        if [[ "$zoo" == "0" ]];then
           echo "extension=zookeeper.so" >> $ini_path
        fi 
        mkdir tmp >> /dev/null 2>&1
        cd tmp
        wget --connect-timeout=10 -Nq http://db1.baike.bjt.a.com:12585/qbus/client/php/deps/php_zookeeper.tar.gz
        tar -zxvf php_zookeeper.tar.gz >> /dev/null 2>&1

        mkdir -p $so_path
        if [[ "$ver" == "5.2" ]];then
            cp zookeeper.so.5.2 zookeeper.so >> /dev/null 2>&1
        elif [[ "$ver" == "5.3" ]];then
            cp zookeeper.so.5.3 zookeeper.so >> /dev/null 2>&1
        elif [[ "$ver" == "5.4" ]];then
            cp zookeeper.so.5.4 zookeeper.so >> /dev/null 2>&1
        else
            cp zookeeper.so.5.5 zookeeper.so >> /dev/null 2>&1
        fi
        cp zookeeper.so $so_path >> /dev/null 2>&1
        rm -rf tmp

        zoo=`$3 -m -c $ini_path |grep zookeeper |wc -l >> /dev/null 2>&1`
        if [[ "$zoo" == "0" ]];then
           echo -e "\033[31"m" zookeeper extension install fail, please install manually \033[0m" 
        fi
    fi

    #compatibile mode
    mkdir -p /home/q/php/
    #will be dir
    rm -rf /home/q/php/kafka_client
    ln -sf $1/client/php /home/q/php/kafka_client
    chown $2:$2 -R /home/q/php/kafka_client
    echo "0|qbus php client install done"
}

function install_cpp_sdk
{

    INSTALL_DIR=$1/client/cpp
    if [ ! -d $INSTALL_DIR ]; then
        sudo mkdir -p $INSTALL_DIR
    fi
    if [ -f $INSTALL_DIR/conf/qbus-client.conf ];then
        mv $INSTALL_DIR/conf/qbus-client.conf /tmp/
    fi
    chmod 755 $1/client
    cd $INSTALL_DIR

    wget --connect-timeout=10 -Nq  http://db1.baike.bjt.a.com:12585/qbus/client/cpp/qbus_client_cpp_infra.tar.gz
    tar -zxvf qbus_client_cpp_infra.tar.gz
    
    rm -rf qbus_client_cpp_infra.tar.gz
    if [ -f /tmp/qbus-client.conf ];then
        mv /tmp/qbus-client.conf conf/ >> /dev/null
    fi

    sudo chown -R $2:$2 $INSTALL_DIR

    DEST=`escape $1`
    cd $1/client/cpp/conf/
    sed -i "s/\/home\/infra\/qbus/$DEST/g" *
    cd $1/client/cpp/examples/
    grep -rl infra  * | xargs  sed -i "s/\/home\/infra\/qbus/$DEST/g"
    install_clean_log $1 $1/client/cpp/log/ $2
    echo "$INSTALL_DIR/lib" > ld-qbus-client.conf
    mv ld-qbus-client.conf /etc/ld.so.conf.d/
    sudo ldconfig

    LD_SO_CONF_D="/etc/ld.so.conf.d/ld-qbus-client.conf"
    if [ ! -d $INSTALL_DIR ] || [ ! -f $LD_SO_CONF_D ]; then
        echo "1|qbus c++ client install failed"
        exit 1
    else
        echo "0|qbus c++ client install done"
        exit 0
    fi
}

function install_java_sdk
{

    INSTALL_DIR=$1/client/java
    if [ ! -d $INSTALL_DIR ]; then
        sudo mkdir -p $INSTALL_DIR
    fi
    if [ -f $INSTALL_DIR/conf/qbus-client.conf ];then
        mv $INSTALL_DIR/conf/qbus-client.conf /tmp/
    fi
    chmod 755 $1/client
    cd $INSTALL_DIR

    wget --connect-timeout=10 -Nq  http://db1.baike.bjt.a.com:12585/qbus/client/java/qbus_client_java_infra.tar.gz
    tar -zxvf qbus_client_java_infra.tar.gz
    
    rm -rf qbus_client_java_infra.tar.gz
    if [ -f /tmp/qbus-client.conf ];then
        mv /tmp/qbus-client.conf conf/ >> /dev/null
    fi

    sudo chown -R $2:$2 $INSTALL_DIR

    DEST=`escape $1`
    cd $1/client/java/conf/
    sed -i "s/\/home\/infra\/qbus/$DEST/g" *
    cd $1/client/java/examples/
    grep -rl infra  * | xargs  sed -i "s/\/home\/infra\/qbus/$DEST/g"
    install_clean_log $1 $1/client/java/log/ $2
    echo "$INSTALL_DIR/lib" > ld-qbus-client.conf
    mv ld-qbus-client.conf /etc/ld.so.conf.d/
    sudo ldconfig

    LD_SO_CONF_D="/etc/ld.so.conf.d/ld-qbus-client.conf"
    if [ ! -d $INSTALL_DIR ] || [ ! -f $LD_SO_CONF_D ]; then
        echo "1|qbus java client install failed"
        exit 1
    else
        echo "0|qbus java client install done"
        exit 0
    fi
}


#Usage info
show_help()
{
    cat << EOF 
Usage: ${0##*/} [-r] [-p php directory] [-f] php.ini
  -h              display this help and exit
  -r              install role: agent, php, cppjava    
  -p              php binary path when -r=php
  -f              php.ini when -r=php
  -C              do not get config.tar.* with wget, assumed that config.tar.* if already deployed
  -G              do not get qbus_agent_infra.tar.* with wget, assumed that qbus_agent_infra.tar.* if already deployed
EOF
}
#  -u              the user who have this files
#  -d              dest directory

DEFAULT_ROOT_DIR="/home/infra/qbus"
DEFAULT_USER="infra"
ROLE=
REAL_DIR=$DEFAULT_ROOT_DIR
REAL_USER=$DEFAULT_USER
PHPINI="/usr/local/php/lib/php.ini"
WGET_CONF_TAR="on"
WGET_AGENT_TAR="on"

if [ "$#" == "0" ];then
    show_help
    exit
fi

while getopts "r:u:d:p:f:CGh" opt; do
    case "$opt" in
        r)
        if [[ -z $OPTARG ]];then
            show_help
        fi
        ROLE=$OPTARG
        ;;
        u)
        if [[ -z $OPTARG ]];then
            show_help
        fi
        REAL_USER=`check_install_user $DEFAULT_USER $OPTARG`
        ;;
        d)
        if [[ -z $OPTARG ]];then
            show_help
        fi
        REAL_DIR=`check_install_dir $DEFAULT_ROOT_DIR $OPTARG`
        ;;
        p)
        if [[ -z $OPTARG ]];then
            show_help
        fi
        PHPPATH=$OPTARG
        ;;
        f)
        if [[ -z $OPTARG ]];then
            show_help
        fi
        PHPINI=$OPTARG
        ;;
        C)
        WGET_CONF_TAR="off"
        ;;
        G)
        WGET_AGENT_TAR="off"
        ;;
        h)       # unknown flag
        show_help
        exit 1
        ;; 
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

check_user
check_user_exist $REAL_USER

if [ "x$ROLE" == "x" ]; then 
    echo 'ERROR: you must specifiy the role which you want to install. See --help.'
    exit
fi

if [ "x$ROLE" == "xphp" ]; then 
    if [ "x$PHPPATH" == "x" ]; then 
        check_php_dir $PHPPATH
        if [ $? == 0 ];then 
          PHPPATH=`check_php_dir $PHPPATH`
        fi
    else
        check_php_dir $PHPPATH
    fi 

    if [ "x$PHPINI" == "x" ]; then
        [ -f $PHPINI ] 
        REV=$?
        [ $REV -ne 0 ] && echo "default php.ini: /usr/local/php/lib/php.ini not exist!" && exit 2
    else
        [ -f $PHPINI ] 
        REV=$?
        [ $REV -ne 0 ] && echo "$PHPINI not exist" && exit 2
    fi
fi

echo "-------- Option Values  --------"
printf '<-r> role      =  %s\n' "$ROLE" 
printf '<-u> user      =  %s\n' "$REAL_USER"
printf '<-d> dest dir  =  %s\n' "$REAL_DIR" 
printf '<-C> wget conf tar  =  %s\n' "$WGET_CONF_TAR" 
if [ "x$ROLE" == "xphp" ]; then 
    printf '<-r> php path  =  %s\n' "$PHPPATH" 
    printf '<-f> php ini   =  %s\n' "$PHPINI" 
fi
if [ "x$ROLE" == "xagent" ]; then 
    printf '<-G> wget agent tar  =  %s\n' "$WGET_AGENT_TAR"
fi
echo 

chmod a+x /home/$REAL_USER

case "$ROLE" in
    "agent")
        check_python
        install_config $REAL_DIR $REAL_USER $WGET_CONF_TAR
        install_cron $REAL_DIR $REAL_USER
        install_agent $REAL_DIR $REAL_USER $WGET_AGENT_TAR
        ;;  
    "php")
        install_config $REAL_DIR $REAL_USER $WGET_CONF_TAR
        install_cron $REAL_DIR $REAL_USER
        install_php_sdk $REAL_DIR $REAL_USER $PHPPATH $PHPINI
        ;;  
    "cpp")
        install_config $REAL_DIR $REAL_USER $WGET_CONF_TAR
        install_cron $REAL_DIR $REAL_USER
        install_cpp_sdk $REAL_DIR $REAL_USER
        ;;  
    "java")
        install_config $REAL_DIR $REAL_USER $WGET_CONF_TAR
        install_cron $REAL_DIR $REAL_USER
        install_java_sdk $REAL_DIR $REAL_USER
        ;;  
esac
exit $?
