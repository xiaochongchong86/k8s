<?php

namespace Qbus3;

class Kafka_Producer {
    private $rk = null;
    private $brokerCluster = null;
    public $topics = array();
    static public $conf = null;
    static private $instance = array();

    static public function getInstance($brokerCluster, $safeSend = true)
    {
        if (!isset(self::$instance[$brokerCluster]))
        {
            self::$instance[$brokerCluster] = new Kafka_Producer($brokerCluster, $safeSend);
        }
        return self::$instance[$brokerCluster];
    }

    public function __construct($brokerCluster, $safeSend = true) {
        if (empty($brokerCluster))
        {
            throw new \KafkaException('brokerCluster cannot be null!');
        }
        $this->brokerCluster = Kafka_Config::getBrokerCluster(strtolower($brokerCluster));
        if (empty($this->brokerCluster))
        {
            throw new \KafkaException('brokerCluster does not exist!');
        }
        $this->safeSend = $safeSend;

        self::$conf = new \RdKafka\Conf();
        self::$conf->set('queue.buffering.max.messages',10000000);
        self::$conf->set('delivery.report.only.error','true');
        self::$conf->setDrMsgCb('\Qbus3\Kafka_Producer::DrMsgCb');

        self::$conf->setErrorCb(function ($kafka, $err, $reason) {
            Kafka_Logger::error("Kafka error: ".rd_kafka_err2str($err). "reason: ".$reason);
        });

        $this->rk = new \RdKafka\Producer(self::$conf);
        $this->rk->setLogLevel(LOG_ERR);
        $this->rk->addBrokers($this->brokerCluster);

        $this->rk->poll(1000);
    }
    static function logerror($msg) {
        $logPath = dirname(__FILE__).'/../../logs';
        $file = $logPath.'/error-log.' . date("Ymd");
        if (!is_file($file)) {
            touch($file);
            @chmod($file, 0777);
        }
        $msg = 'ERROR ['.date("Y-m-d H:i:s").']  '.$msg."\n";
        file_put_contents($file, $msg, FILE_APPEND);
    }
    public static function DrMsgCb($kafka, $msg){
        if ($msg && $msg->err) {
            Kafka_Producer::logerror("msg send failed ".$msg->errstr());
        } else {
            Kafka_Producer::logerror("msg send failed without msg value");
        }
    }

    public function send($messages, $cur_topic, $flag = Kafka_ConstDef::MESSAGE_RANDOM_SEND, $semanticKey = '') {
        $ret = false;
        if (!array_key_exists($cur_topic,$this->topics)) {
            $this->topics[$cur_topic] = $this->rk->newTopic($cur_topic);
        }
        $tryTimes = 0;
        while($ret === false) {
            try {
                if (!is_array($messages)) {
                    $this->topics[$cur_topic]->produce(RD_KAFKA_PARTITION_UA, 0, $messages, $semanticKey);
                } else {
                    foreach($messages as $msg) {
                        $this->topics[$cur_topic]->produce(RD_KAFKA_PARTITION_UA, 0, $msg, $semanticKey);
                    }
                }
                $ret = true;
                break;
            } catch (Exception $e) {
                Kafka_Logger::error("producer get exception, errmsg:".$e->getMessage(), $e->getCode());
                $ret = false;
            }
            if (++$tryTimes >= 5){
                break;
            }
            usleep(3 * Kafka_Config::$sleepMicroSec);
        }

        return $ret;
    }
}


