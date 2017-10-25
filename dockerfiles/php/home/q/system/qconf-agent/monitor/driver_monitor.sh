#! /bin/sh

# crontab for qconf 0.2.* and 0.1.*
#*/1 * * * * cd /home/q/php/Qconf/monitor && sh driver_monitor.sh >> /dev/null 2>&1
# crontab for qconf 0.3.0, 0.3.1
#*/1 * * * * cd /home/q/system/qconf-agent/monitor && sh driver_monitor.sh >> /dev/null 2>&1

(
flock -n -e 200 ||{ echo "qconf agent monitor already exist! No need to execute again!" ; exit 1 ; }

sh qconf_monitor.sh

)200>monitor_lockfile
