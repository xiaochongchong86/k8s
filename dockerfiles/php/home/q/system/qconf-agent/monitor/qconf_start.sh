#!/bin/sh

#*/1 * * * * cd /home/q/php/qconf_alarm && sh qconf_start.sh
#lockf -k  -t 0 lockfile /usr/local/bin/php qconf_consumer.php
#lockf -t 0 lockfile sleep 20

(
flock -n -e 200 || { echo "lockfile has been locked!"; exit -1; }
/usr/local/bin/php qconf_consumer.php
)200>lockfile