#!/bin/sh

## wget the configure and restart agent if necessary
wget_driver_configure_and_restart_agent_if_necessary () {
    local_monitor_path=`pwd`
    cd ../conf/wget 
    if [ -e "qconf.newconf" ]; then
        mv qconf.newconf qconf.newconf.bak
    fi
    if [ -e "qconf.newconf.md5" ]; then
        mv qconf.newconf.md5 qconf.newconf.md5.bak
    fi

    # get the md5 file, and first check the md5 with the qconf.conf
    for (( i=0; $i < 5; i++)); 
    do
        wget qconf-conf.add.corp.a.com:8360/qconf-conf/qconf.newconf.md5
        if [ "$?" != "0" ]; then
            echo "Get qconf.newconf.md5 failed! try times: $i"
            sleep 1
        else
            break;
        fi
    done
    if (( $i == 5 )); then
        msg="Get qconf.newconf.md5 $i times failed!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    if [[ ! -e qconf.newconf.md5 ]]; then
        msg="Get qconf.newconf.md5 failed! The file not exists!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    chmod 0666 qconf.newconf*

    qconf_newconf_md5_content=`cat qconf.newconf.md5`
    qconf_conf_md5=`md5sum ../qconf.conf | cut -d ' ' -f 1`
    if [[ "$qconf_newconf_md5_content" = "$qconf_conf_md5" ]]; then
        echo "The content of qconf.newconf is equal to qconf.conf, no need to update";
        cd $local_monitor_path
        return 0
    fi

    # if md5 is new, then download the new qconf.newconf file
    for (( i=0; $i < 5; i++)); 
    do
        wget qconf-conf.add.corp.a.com:8360/qconf-conf/qconf.newconf
        if [ "$?" != "0" ]; then
            echo "Get qconf.newconf failed! try times: $i"
            sleep 1
        else
            break;
        fi
    done
    if (( $i == 5 )); then
        msg="Get qconf.newconf $i times failed!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    if [[ ! -e qconf.newconf ]]; then
        msg="Get qconf.newconf failed! The file not exists!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    chmod 0666 qconf.newconf*

    qconf_newconf_get_md5=`md5sum qconf.newconf | cut -d ' ' -f 1`
    if [[ "$qconf_newconf_get_md5" != "$qconf_newconf_md5_content" ]]; then
        msg="The md5 of qconf.newconf is not equal to qconf.newconf.md5";
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi

    mv ../qconf.conf ../bak/qconf.conf.bak
    cp qconf.newconf ../qconf.conf
    chmod 0666 ../qconf.conf
    cd $local_monitor_path
    if [[ -e "../conf/agent.conf" ]]; then
        echo "agent.conf exists, the qconf.conf now is just for qconf extension"
        return 0
    fi

    echo "update qconf.conf success, now restart qconf agent"
    cd .. && sh agent-cmd.sh restart
    if [[ "$?" = "0" ]]; then
        echo "restart agent success!"
    fi

    cd $local_monitor_path
}

# wget agent configure and restart agent is necessary
wget_agent_configure_and_restart_agent_if_necessary () {
    # check whether exist the agent file
    
    local_monitor_path=`pwd`
    if [ ! -e "../conf/agent.conf" ]; then
        echo "agent.conf not exists, then no need to update the agent.conf"
        return 0
    fi

    cd ../conf/wget 
    if [ -e "agent.newconf" ]; then
        mv agent.newconf agent.newconf.bak
    fi
    if [ -e "agent.newconf.md5" ]; then
        mv agent.newconf.md5 agent.newconf.md5.bak
    fi

    # get the md5 file, and first check the md5 with the agent.conf
    for (( i=0; $i < 5; i++)); 
    do
        wget qconf-conf.add.corp.a.com:8360/qconf-conf/agent.newconf.md5
        if [ "$?" != "0" ]; then
            echo "Get agent.newconf.md5 failed! try times: $i"
            sleep 1
        else
            break;
        fi
    done
    if (( $i == 5 )); then
        msg="Get agent.newconf.md5 $i times failed!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    if [[ ! -e agent.newconf.md5 ]]; then
        msg="Get agent.newconf.md5 failed! The file not exists!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    chmod 0666 agent.newconf*

    agent_newconf_md5_content=`cat agent.newconf.md5`
    agent_conf_md5=`md5sum ../agent.conf | cut -d ' ' -f 1`
    if [[ "$agent_newconf_md5_content" = "$agent_conf_md5" ]]; then
        echo "The content of agent.newconf is equal to agent.conf, no need to update";
        cd $local_monitor_path
        return 0
    fi

    # if md5 is new, then download the new agent.newconf file
    for (( i=0; $i < 5; i++)); 
    do
        wget qconf-conf.add.corp.a.com:8360/qconf-conf/agent.newconf
        if [ "$?" != "0" ]; then
            echo "Get agent.newconf failed! try times: $i"
            sleep 1
        else
            break;
        fi
    done
    if (( $i == 5 )); then
        msg="Get agent.newconf $i times failed!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    if [[ ! -e agent.newconf ]]; then
        msg="Get agent.newconf failed! The file not exists!"
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi
    chmod 0666 agent.newconf*

    agent_newconf_get_md5=`md5sum agent.newconf | cut -d ' ' -f 1`
    if [[ "$agent_newconf_get_md5" != "$agent_newconf_md5_content" ]]; then
        msg="The md5 of agent.newconf is not equal to agent.newconf.md5";
        cd $local_monitor_path
        alarm_by_all_way $msg
        return -1
    fi

    mv ../agent.conf ../bak/agent.conf.bak
    cp agent.newconf ../agent.conf
    chmod 0666 ../agent.conf
    echo "update agent.conf success, now restart qconf agent"
    cd $local_monitor_path
    cd .. && sh agent-cmd.sh restart
    if [[ "$?" = "0" ]]; then
        echo "restart agent success!"
    fi
    cd $local_monitor_path
}
#wget_configure_and_restart_agent_if_necessary

check_whether_wget () {
    if [[ "$1" = "--force" ]]; then
        echo "Now force wget the qconf.newqconf"
        wget_driver_configure_and_restart_agent_if_necessary
        wget_agent_configure_and_restart_agent_if_necessary
        return $? 
    fi

    cur_idc=`cat ../conf/localidc`
    if [ "$cur_idc" = "corp" ]; then
        echo "corp no need to update"
        return 0
    fi

    cur_hour=`date +%H`
    cur_min=`date +%M`

    cur_hour=${cur_hour#0}
    cur_min=${cur_min#0}

    echo "hour: $cur_hour"
    echo "minute: $cur_min"

    if (( $cur_hour != 3 )); then
        echo "not in the time for updating"
        return 0
    fi

    wget_time=`cat wget_time`
    if [[ "$wget_time" = "" ]]; then
        wget_time=23
        echo $wget_time > wget_time
    fi
    if (( "$cur_min" != "$wget_time" )); then
        echo "not in the minute for updating"
        return 0
    fi

    echo "now wget the qconf.newqconf"
    wget_driver_configure_and_restart_agent_if_necessary
    wget_agent_configure_and_restart_agent_if_necessary
    return $?
}

check_whether_wget $@
