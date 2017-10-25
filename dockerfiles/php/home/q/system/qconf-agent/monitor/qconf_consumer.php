<?php

require '/home/q/php/kafka_client/lib/kafka_client.php';
#require 'lib/kafka_client.php';

ini_set('date.timezone','Asia/Shanghai');

// qbus infor
$zkCluster = 'center';
$topic = 'qconf_alarm';
$group = 'default';

// alarm infor
$GROUP_MAIL = "qconf";
$SUBJECT = "QConf Alarm";
$CENTER_MAIL = "http://alarms.ops.a.com:8360/intfs/alarm_intf";
$CENTER_SMS = "http://alarms.ops.a.com:8360/intfs/sms_intf";
$QALARM = "http://message.alarm.add.corp.a.com:8360/send/?to=22&type=group&level=2";

$consumer = new Kafka_Consumer($zkCluster, $topic, 'qconf_alarm_func', $group);
$consumer->work();

// qconf alarm function
function qconf_alarm_func($msg)
{
    echo "qconf test: $msg\n"; 

    qconf_check_msg($msg);

    return true;
}

class QconfInfoUtil                                                                    
{                                                                                      
    const MAX_PROCESS_TBL_NUM = 20;                                                    
    const MAX_NOT_FOUND_NUM = 20;                                                      

    const PROCESS_INFO = "process_tbl zookeeper operation failed";                     
    const NOT_FOUND_INFO = "QCONF_WAIT, Not get value from share memory!";             
}                                                                                      
                                                                                       
$process_tbl_array = array();                                                          
$not_found_array = array();                                                            
function qconf_check_msg($msg)
{                                                                                      
    global $process_tbl_array;                                                         
    global $not_found_array;                                                           

    if (strpos($msg, QconfInfoUtil::PROCESS_INFO) !== FALSE)                           
    {                                                                                  
        if (count($process_tbl_array) < QconfInfoUtil::MAX_PROCESS_TBL_NUM)            
        {                                                                              
            $process_tbl_array[] = $msg;                                               
        }                                                                              
        else                                                                           
        {                                                                              
            $alarm_msg = "";                                                           
            $process_tbl_array[] = $msg;
            foreach ($process_tbl_array as $key => $value)                             
            {                                                                          
                $pos = strpos($value, ']');
                $pos = strpos($value, ']', $pos + 1);
                $pos = strpos($value, ']', $pos + 1);

                $new_key = substr($value, 0, $pos + 1);

                $path_pos = strpos($value, "path:");
                $comma_pos = strpos($value, ",", $path_pos);
                $path = substr($value, $path_pos, $comma_pos - $path_pos);

                $new_array[$new_key] = $path;

                unset($process_tbl_array[$key]);                                       
            }

            foreach ($new_array as $key => $value)
            {
                $alarm_msg .= $key . " : " . QconfInfoUtil::PROCESS_INFO . "; " . $value . "\n";                                           
                unset($new_array[$key]);
            }                                                                          
            alarm_by_whole($alarm_msg);                                                    
        }                                                                              
    } 
    else if (strpos($msg, QconfInfoUtil::NOT_FOUND_INFO) !== FALSE)                 
    {                                                                               
        if (count($not_found_array) < QconfInfoUtil::MAX_NOT_FOUND_NUM)             
        {                                                                           
            $not_found_array[] = $msg;                                              
        }                                                                           
        else                                                                        
        {                                                                           
            $alarm_msg = "";                                                        
            $not_found_array[] = $msg;                                              
            foreach ($not_found_array as $key => $value)                             
            {                                                                          
                $pos = strpos($value, ']');
                $pos = strpos($value, ']', $pos + 1);
                $pos = strpos($value, ']', $pos + 1);

                $new_key = substr($value, 0, $pos + 1);

                $path_pos = strpos($value, "path:");
                $comma_pos = strpos($value, ",", $path_pos);
                $path = substr($value, $path_pos, $comma_pos - $path_pos);

                $new_array[$new_key] = $path;

                unset($not_found_array[$key]);                                       
            }

            foreach ($new_array as $key => $value)
            {
                $alarm_msg .= $key . " : " . QconfInfoUtil::NOT_FOUND_INFO . "; " . $value . "\n";                                           
                unset($new_array[$key]);
            }                                                                          
            alarm_by_whole($alarm_msg);                                                 
        }                                                                           
    }                                                                               
    else                                                                            
    {                                                                               
        alarm_by_whole($msg);                                                           
    }                                                                               
}

function alarm_by_whole($msg)
{
    echo "$msg";
    alarm_by_qhemail($msg);
    alarm_by_qalarm($msg);

    return true;
}

function alarm_by_qalarm($msg)
{
    global $QALARM;
    $msg = urlencode($msg);
    echo "qalarm: $msg" . PHP_EOL;

    exec("curl -s '$QALARM&content=$msg'", $res, $ret);
    var_dump($res);
}

function alarm_by_qhemail($msg)
{
    global $GROUP_MAIL;
    global $SUBJECT;
    global $CENTER_MAIL;
    echo "qhemail $msg" . PHP_EOL;

    exec("curl -d 'group_name=$GROUP_MAIL' -d 'subject=$SUBJECT' -d 'content=$msg' $CENTER_MAIL -s", $res, $ret);
}

?>
