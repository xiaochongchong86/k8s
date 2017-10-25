#!/bin/sh
 
function add_cmd_in_crontab()
{
    user=$1
    if [[ $user = "" ]]; then
        user=infra
    fi
    cmd="cd /home/q/system/qconf-agent/monitor && sh driver_monitor.sh >> /dev/null 2>&1"

    echo "user: " $user
    echo "cmd : " $cmd

    cron_tab="/var/spool/cron/$user"
    status=`sudo grep "$cmd" $cron_tab`
    if [ -z "$status" ]; then
        echo "'$cmd' is not in the $user corntab"
        echo "*/1 * * * * $cmd" >> $cron_tab                                                                                           
        echo "insert '$cmd' into the crontab SUCCESS!"
    else 
        status=`sudo grep "$cmd" $cron_tab | sudo grep "^#"`
        if [ -z "$status" ]; then
            echo "'$cmd' is already in the crontab"
        else
            echo 
            echo '  ======================== '
            echo "Notice: '$cmd' has been annotated, You should deal with it! Using 'sudo crontab -e'!"
            echo '  ======================== '
            echo 
        fi  
    fi  

    exit 0
}

# add the command into the infra crontab
# $1 : the user name,    defalut : infra
add_cmd_in_crontab $1
