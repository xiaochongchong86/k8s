<?php
use Qbus3\Kafka_Consumer;

#!/usr/bin/php

require '../lib/kafka_client.php';

ini_set('date.timezone','Asia/Shanghai');

$brokerlist = 'test';
$topic = 'offsetconsume';
$group = 'default';
$consumer = new Kafka_Consumer($brokerlist, $topic, 'myfunc',$group);
$param = array(
    'socketTimeout' => 3,
    'singleOffsetCommit' => false,
    'maxTryTimes' => 1,
    );
$consumer->setParam($param);

$consumer->work();
function myfunc($msg){
    echo "$msg\n";
    usleep(100);
    //sleep(1); */
    return true;
}
