#!/bin/sh

sh qconf_idc_set.sh

# add the command into the user 'infra' crontab
id infra >/dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "\033[1;33muser '\033[1;31minfra\033[1;33m' is not exist, please ask OPS to the user!!!!\033[0m"
    exit -1
else
    echo "'infra' exist"

    chown -R infra:infra /home/q/system/qconf-agent
    chmod -R 0777 /home/q/system/qconf-agent/logs
    
    # start the qconf agent
    killall -9 qconf_agent
    sudo -u infra sh -c "cd /home/q/system/qconf-agent && sh agent-cmd.sh start"

    sh qconf_deploy_crontab.sh
fi
