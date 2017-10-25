#!/usr/bin/php
<?php

use Qbus3\Kafka_Producer;
require '../lib/kafka_client.php';
ini_set('date.timezone','Asia/Shanghai');

$brokerlist = "test";
$topic = 'aa-phplowapi-test';
$sender = Kafka_Producer::getInstance($brokerlist);

//send a single message synchronously
$i = 0;
$count = 10;
while (1)
{
    echo $i++;
    if ($i === $count){
        break;
    }
    $msg = 'sample message'.$i;
    $ret = $sender->send($msg, $topic);
}

//send many messages each time
//$msg =array('test msg3', 'test msg4');
//$ret = $sender->send($msg, $topic);
//var_dump($ret);
