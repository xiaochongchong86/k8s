#!/bin/sh

set_random_wget_time () {
    t=`hostname | md5sum | cut -d ' ' -f 1`
    t=${t:0:16}
    t=0x$t
    (( t = $t % 60 ))
    if (( $t < 0 )); then
        (( t = -$t ));
    fi
    echo "wget_time minute: " $t
    echo $t > /home/q/system/qconf-agent/monitor/wget_time 
}

set_localidc () {
    localidc=`hostname | awk -F '.' '{if (NF >= 3 && $NF == "net" && $(NF-1) == "qihoo") { print $(NF-2)}}'`

    if [ "$localidc" = "" ]; then
        echo -e "\033[1;33mhostname is not right!\033[0m\n"
    else
        echo "localidc: " $localidc
        echo $localidc > /home/q/system/qconf-agent/conf/localidc
    fi
}

set_random_wget_time
set_localidc
