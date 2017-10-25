#!/bin/sh

# qconf 0.3.1

#host and cur_ips
host=$(hostname)
echo $host
cur_ips=$(/sbin/ifconfig | grep "inet addr" | cut -f 2 -d ":" | cut -f 1 -d " " | grep -v "127.0.0.1")
echo $cur_ips

MAX_INTEVAL=3600
MAX_FREQUENRY_NUM=5
MAX_LOG_NUM=1

#EXPIRE_FILE="/home/liuzhongchao/code/qconf/driver/independent-agent/qconf-agent/monitor/qconf_expire_file"
EXPIRE_FILE="qconf_expire_file"
        
GROUP_MAIL="qconf"
CENTER_MAIL="http://alarms.ops.a.com:8360/intfs/alarm_intf"
CENTER_SMS="http://alarms.ops.a.com:8360/intfs/sms_intf"
#QALARM="http://message.alarm.add.corp.a.com:8360/?p=report&c=client&a=message&format=json"
QALARM="http://message.alarm.add.corp.a.com:8360/send/?to=22&type=group&level=2"
QBUS_ALARM="http://alarm.add.corp.a.com:8360/qbus_httpproducer.php"

#alarm user and phones
#names=(liuzhongchao)
names=(liuzhongchao wangkang-xy zhuchao wangchao3)
phoneno=(15701526954 18603516550 15801673740 18611131918)

#content init
SUBJECT="QConf Alarm"
content=""

# way of alarm 
alarm_by_sms () {
    local_sms_content="$@"
    length=${#phoneno[@]}
    for (( i = 0; i < $length; i++ )); do
        no=${phoneno[$i]}
        echo $no
        local_sms_content=${local_sms_content:0:40}
        echo "phone: $local_sms_content"
        curl -d "mobiles=$no" -d "msg=[QConf][$host][$cur_ips]$SUBJECT $local_sms_content" $CENTER_SMS -s
    done
}

alarm_by_qhemail () {
    local_qhe_content="$@"
    echo "qhemail: $local_qhe_content"
    curl -d "group_name=$GROUP_MAIL" -d "subject=$SUBJECT" -d "content=[QConf][$host][$cur_ips] $local_qhe_content" $CENTER_MAIL -s
}

alarm_by_qalarm () {
    local_qa_content=$@
    echo "qalarm: $local_qa_content"
    curl $QALARM"&content=\[Qconf\]\[$host\]\[$cur_ips\]: $local_qa_content" -s
}

alarm_by_qbus_alarm () {
    local_qba_content=$@
    echo "qbus: $local_qbus_content"
    curl -d"cluster=center" -d"topic=qconf_alarm" -d"msg=[QConf][$host][$cur_ips] $local_qba_content" -d"token=96bc0c7d079a054e7329257a2f837778" $QBUS_ALARM
}

alarm_by_all_way () {
#    alarm_by_sms $@
#    alarm_by_qhemail $@
#    alarm_by_qalarm $@
    alarm_by_qbus_alarm $@
}

#alarm_by_all_way "now test for qalarm group and qhemail group"
#alarm_by_all_way "now test use qbus qalarm"

# alarm strategy
alarm_for_exceed () {
#    echo "alarm for exceed func in ... "
    if [ -e $EXPIRE_FILE ]; then
        str=$(cat $EXPIRE_FILE)
#        echo $EXPIRE_FILE $str
        frequenry_whole=${str%#*}
        log_whole=${str#*#}

#        echo frequenry_whole: $frequenry_whole
#        echo log_whole: $log_whole

        cur_time=`date +%s`

        frequenry_time=${frequenry_whole%:*}
        frequenry_num=${frequenry_whole#*:}

        if (( ($cur_time - $frequenry_time) < $MAX_INTEVAL )); then
            (( frequenry_num = $frequenry_num + 1 ))
            if (( $frequenry_num < $MAX_FREQUENRY_NUM )); then
                echo "$frequenry_time:$frequenry_num#$log_whole" > $EXPIRE_FILE
            else
                echo "now alarm ...."
                alarm_by_all_way $@
                echo "$frequenry_time:0#$log_whole" > $EXPIRE_FILE
            fi  
        else 
            echo "$cur_time:1#$log_whole" > $EXPIRE_FILE
        fi  
    else
        cur_time=`date +%s`
        echo "$cur_time:1#$cur_time:0" > $EXPIRE_FILE
        if [ "$?" != "0" ]; then
            echo "alarm create $EXPIRE_FILE failed!"
            alarm_by_all_way "create $EXPIRE_FILE failed!"
        else
            chmod 0666 $EXPIRE_FILE
        fi  
    fi  
}

alarm_for_log () {
    cur_num=$1
    if [ -e $EXPIRE_FILE ]; then
        str=$(cat $EXPIRE_FILE)
#        echo $str
        frequenry_whole=${str%#*}
        log_whole=${str#*#}

#        echo frequenry_whole: $frequenry_whole
#        echo log_whole: $log_whole

        cur_time=`date +%s`

        log_time=${log_whole%:*}
        log_num=${log_whole#*:}
        if (( $cur_num < $MAX_LOG_NUM )); then
            echo "$frequenry_whole#$cur_time:$cur_num" > $EXPIRE_FILE
        else
            if (( ($cur_time - $log_time) < $MAX_INTEVAL )); then
                if (( $cur_num != $log_num )); then
                    echo "now alarm for log..."
                    alarm_by_all_way $@ 
                    echo "$frequenry_whole#$cur_time:$cur_num" > $EXPIRE_FILE
                fi
            else
                echo "expire first alarm for log ..."
                alarm_by_all_way $@
                echo "$frequenry_whole#$cur_time:$cur_num" > $EXPIRE_FILE
            fi
        fi
    else
        cur_time=`date +%s`
        echo "$cur_time:0#$cur_time:$cur_num" > $EXPIRE_FILE
        if [ "$?" != "0" ]; then
            echo "alarm create $EXPIRE_FILE failed!"
            alarm_by_all_way "alarm for log: create $EXPIRE_FILE failed!"
        else
            chmod 0666 $EXPIRE_FILE
            if (( $cur_num >= $MAX_LOG_NUM )); then
                echo "now first alarm for log ..."
                alarm_by_all_way $@
            fi
        fi
    fi
} 

# check process status
## whether live?
PROCESS_NAME=qconf_agent
check_whether_live () {
    qconf_num=$(ps aux | grep -v grep | grep -c $PROCESS_NAME$)
    if (( $qconf_num < 2 )); then
        cur_path=`pwd`
#        cd /home/q/system/qconf-agent && sh agent-cmd.sh start
        cd .. && sh agent-cmd.sh start
        if [ "$?" != 0 ]; then
            cd $cur_path
            echo "alarm for qconf agent is not running ... "
            alarm_for_exceed "qconf agent is not running ..."
        else
            cd $cur_path
            echo "start qconf-agent successful"
        fi
    else
        echo "qconf agent is live"
    fi
}

# check whether localidc is null
check_localidc () {
    local_idc=`hostname | awk -F '.' '{if (NF >= 3 && $NF == "net" && $(NF-1) == "qihoo") { print $(NF-2)}}'`

    if [[ ! -e "../conf/localidc" ]]; then
        if [[ "local_idc" != "" ]]; then
            echo $local_idc > ../conf/localidc 
            if [[ "$?" != "0" ]]; then
                msg="file ../conf/localidc not exist"
                echo $msg
                alarm_for_exceed $msg
            fi
            chmod 0666 ../conf/localidc
        else
            msg="file ../conf/localidc not exist"
            echo $msg
            alarm_for_exceed $msg
        fi
    fi
    
    localidc=`cat ../conf/localidc`
    if [[ "$localidc" = "" ]]; then
        if [[ "local_idc" != "" ]]; then
            echo $local_idc > ../conf/localidc 
            if [[ "$?" != "0" ]]; then
                msg="local idc is null, please set it"
                echo $msg
                alarm_for_exceed $msg
            fi
            chmod 0666 ../conf/localidc
        else
            msg="local idc is null, please set it"
            echo $msg
            alarm_for_exceed $msg
        fi
    else
        if  [[ "$localidc" != "$local_idc" ]]; then
            msg="localidc changed from '$localidc' to '$local_idc'! Please check it!"
            echo $msg
            alarm_for_exceed $msg
        fi
    fi
}

### whether lock?
#check_whether_lock () {
#}

LOG_DIR=/home/q/system/qconf-agent/logs
LOG_PREIFX=qconf.log
# check log
check_log () {
    log_time=$(date +%Y-%m-%d-%H)
    log_file="$LOG_DIR/$LOG_PREIFX.$log_time"
#    echo $log_file
    fatal_err_num=$(grep "FATAL ERROR" $log_file | wc -l)
    if [ "$fatal_err_num" != "0" ]; then
        echo "fatal_err_num: " $fatal_err_num
        fatal_errs=$(grep 'FATAL ERROR' $log_file | cut -d ']' -f 2-4 | sort | uniq)
        fatal_errs=${fatal_errs//[/(}
        fatal_errs=${fatal_errs//]/)}
        fatal_errs=${fatal_errs//\*/\\*}
        echo "$fatal_errs"
        alarm_for_log "$fatal_err_num" "$fatal_errs"
    else
        echo "qconf runs GOOD! No fatal error log!"
    fi
}

check_whether_live
check_log
check_localidc
. ./qconf_update_conf.sh
