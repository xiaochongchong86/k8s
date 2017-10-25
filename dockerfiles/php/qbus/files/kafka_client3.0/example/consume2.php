#!/usr/bin/php
<?php

require '../lib/kafka_client.php';

ini_set('date.timezone','Asia/Shanghai');

$cluster = $argv[1];
$topic = $argv[2];
$group = $argv[3];
$consumer = new Kafka_Consumer($cluster, $topic, 'myfunc', $group, true);

$consumer->work();
function myfunc($msg){
    return true;
}
die();