<?php

namespace Qbus3;

use Utils\ZookeeperC;
use Utils\ZkUtil;

class Kafka_Consumer {
	private $consumer = null;
	private $topic = null;
	private $brokerCluster = null;
	private $zkServers = null;
	private $conf = null;
	private $topicConf = null;
	private $groupId = null;
	private $zkClient = null;
	private $partition_ids = [ ];
	private $partitions_obj = [ ];
	private $partition_current_offset = [ ];
	private $seekOffsetVersion = 0;
	
	public function __construct($brokerlist, $topic, $callback, $groupId = 'default') {
		if (! is_callable ( $callback ) || empty ( $topic )) {
			throw new \KafkaException ( 'invalid callback function or topic!' );
		}
		$this->addProcessFunc ( $topic, $callback, $groupId );
		$this->topic = $topic;
		$this->groupId = $groupId;
		$this->brokerCluster = Kafka_Config::getBrokerCluster ( strtolower ( $brokerlist ) );
		$this->zkServers = Kafka_Config::getZkCluster ( strtolower ( $brokerlist ) );
		if (! $this->brokerCluster) {
			throw new \KafkaException ( 'invalid brokerlist!' );
		}
		if (! $this->zkServers) {
			throw new \KafkaException ( 'invalid zkcluster!' );
		}
		$this->consumer_name = ZkUtil::getConsumerName ();
		$this->zkClient = new ZookeeperC ( $this->zkServers );
		Kafka_Logger::info ( 'broker ' . $this->brokerCluster . " zkServers" . $this->zkServers );
	}
	
	private function reconnectZK() {
		$this->zkClient = new ZookeeperC ( $this->zkServers );
		ZkUtil::createConsumerPid ( $this->zkClient, $this->topic, $this->groupId, $this->partition_ids, $this->consumer_name );
		Kafka_Logger::info ( "reconnectZK: " . json_encode ( $this->zkClient ) );
	}
	
	private function init() {
		$conf = new \Rdkafka\Conf ();
		$conf->set ( 'group.id', $this->groupId );
		$conf->set ( 'metadata.broker.list', $this->brokerCluster );
		$conf->set ( 'enable.auto.commit', 'false' );
		$conf->set ( 'queue.buffering.max.ms', 100 );
		$conf->set ( 'socket.blocking.max.ms', 10 );
		$conf->set ( 'socket.timeout.ms', Kafka_Config::$socketTimeout * 1000 );
		
		$topicConf = new \Rdkafka\TopicConf ();
		$topicConf->set ( 'auto.offset.reset', 'smallest' );
		
		$conf->setDefaultTopicConf ( $topicConf );
		
		$conf->setRebalanceCb ( function (\RdKafka\KafkaConsumer $kafka, $err, array $partitions = null) {
			$tp = "";
			$parts = "";
			$c_partition = [ ];
			foreach ( $partitions as $i => &$part ) {
				$tp = $part->getTopic ();
				$c_partition [$i] = $part->getPartition ();
				$parts .= " " . $c_partition [$i];
				if (isset ( $this->partition_current_offset [$tp] [$c_partition [$i]] )) { // 只有自己的offset 如别的 消费者 这里还需要处理
					$part->setOffset ( $this->partition_current_offset [$tp] [$c_partition [$i]] + 1 );
				}
			}
			switch ($err) {
				case RD_KAFKA_RESP_ERR__ASSIGN_PARTITIONS :
					Kafka_Logger::info ( 'assign topic ' . $tp . ' partitions' . $parts );
					$kafka->assign ( $partitions );
					$this->partition_ids = array_values ( $c_partition );
					$this->partitions_obj = $partitions;
					ZkUtil::createConsumerPid ( $this->zkClient, $this->topic, $this->groupId, $this->partition_ids, $this->consumer_name );
					break;
				
				case RD_KAFKA_RESP_ERR__REVOKE_PARTITIONS :
					Kafka_Logger::info ( 'assign topic ' . $tp . ' partitions' . $parts . " null");
					$kafka->assign ( NULL );
					break;
				
				default :
					throw new \Exception ( $err );
			}
		} );
		
		$this->setSeekOffsetVersion();//init seekoffsetversion = 0
		$this->consumer = new \Rdkafka\KafkaConsumer ( $conf );
		$this->consumer->subscribe ( [ 
				$this->topic 
		] );
	}
	
	private function setSeekOffsetVersion() {
		$this->seekOffsetVersion = $this->getSeekOffsetVersionVal();
		Kafka_Logger::info("init seekOffsetVersion: ".$this->seekOffsetVersion);
	}
	
	private function getSeekOffsetVersionVal() {
		$seekoffsetversion = ZkUtil::getOffsetVsersionPath ( $this->topic, $this->groupId );
		$val = $this->seekOffsetVersion; //init 0
		if ($this->zkClient->exists ( $seekoffsetversion )){
			$val = $this->zkClient->get($seekoffsetversion);
		}
		return $val;
	}
	
	/**
	 * 是否有新的seekoffset
	 * 
	 * @return boolean
	 */
	private function checkNewSeekOffset() {
		$newSeekOffset = ZkUtil::getGloblePartSeekOffsetMap ( $this->zkClient, $this->topic, $this->groupId );
		Kafka_Logger::info ( 'seekoffset. ' . json_encode ( $newSeekOffset ) );
		if ($newSeekOffset) {
			$newPartition = [ ];
			foreach ( $this->partitions_obj as $partition ) {
				$current_topic = $partition->getTopic ();
				$current_partition = $partition->getPartition ();
				$current_offset = $partition->getOffset ();
				Kafka_Logger::info ( "current_topic: {$current_topic}, current_partition: {$current_partition}, current_offset: {$current_offset}" );
				if (isset ( $newSeekOffset [$current_partition] )) {
					$newPartition [] = new \RdKafka\TopicPartition ( $current_topic, $current_partition, $newSeekOffset [$current_partition] );
					Kafka_Logger::info ( "newoffset current_topic: {$current_topic}, current_partition: {$current_partition}, current_offset: {$newSeekOffset[$current_partition]}" );
				} else {
					$current_offset = isset ( $this->partition_current_offset [$current_topic] [$current_partition] ) ? $this->partition_current_offset [$current_topic] [$current_partition] + 1 : $current_offset;
					Kafka_Logger::info ( "partition_current_offset: " . json_encode ( $this->partition_current_offset ) );
					$newPartition [] = new \RdKafka\TopicPartition ( $current_topic, $current_partition, $current_offset );
					Kafka_Logger::info ( "oldoffset current_topic: {$current_topic}, current_partition: {$current_partition}, current_offset: {$current_offset}" );
				}
			}
			if ($newPartition) {
				try {
					$this->consumer->assign ( $newPartition );
					Kafka_Logger::info ( "consumer assign suc" );
				} catch ( \Exception $e ) {
					Kafka_Logger::info ( "consumer assign fail error: ".$e->getMessage() );
				}
			}
		}
		return true;
	}
	public function setParam(array $params) {
		foreach ( $params as $param => $val ) {
			if (isset ( Kafka_Config::$$param )) {
				Kafka_Config::$$param = $val;
			}
		}
	}
	private function addProcessFunc($topic, $callback, $groupId = 'default') {
		$processInfo ['callback'] = $callback;
		$processInfo ['topic'] = $topic;
		$processInfo ['groupId'] = $groupId;
		$processInfo ['partInfo'] = array ();
		$this->topicProcessInfo [$topic] = $processInfo;
		$this->prePollTime [$topic] = 0;
	}
	public function work() {
		$this->init ();
		while ( 1 ) {
			$message = $this->consumer->consume ( 15e3 );//Kafka_Config::$sleepMicroSec
			
			switch ($message->err) {
				case RD_KAFKA_RESP_ERR_NO_ERROR :
					foreach ( $this->topicProcessInfo as $topic => &$processInfo ) {
						$this->_processTopic ( $processInfo, $message );
					}
					break;
				case RD_KAFKA_RESP_ERR__PARTITION_EOF :
					break;
				case RD_KAFKA_RESP_ERR__TIMED_OUT :
						Kafka_Logger::info("timeout trigger check verison");
						$this->checkSeekOffsetVersion();//如果没有消费数据过来  那么设置一个检查版本号的超时时间
					break;
				default :
					Kafka_Logger::error ( $this->brokerCluster . " get message gexception" . $message->errstr () . $message->err . " partition: ".json_encode($this->partition_ids));
					throw new \Exception ( $message->errstr (), $message->err );
					break;
			}
		}
	}
	
	private function _processTopic(&$processInfo, $message) {
		$topic = $processInfo ['topic'];
		$groupId = $processInfo ['groupId'];
		$payload = $message->payload;
		$tryTimes = 0;
		while ( call_user_func ( $processInfo ['callback'], $payload ) === false ) {
			if (++ $tryTimes >= Kafka_Config::$maxTryTimes) {
				break;
			}
		}
		$this->partition_current_offset[$topic][$message->partition] = $message->offset;
		if (Kafka_Config::$singleOffsetCommit || $message->offset % Kafka_Config::$CommitIntevalCounts === 0) {
			Kafka_Logger::info ( 'topic ' . $message->topic_name . ' partition ' . $message->partition . ' offset ' . $message->offset . ' commited' );
			$this->consumer->commit ( $message );
			
			if (mt_rand(1, 4) == 3) {// 20%
				Kafka_Logger::info("commit trigger check verison");
				$this->checkSeekOffsetVersion();//每次提交之后检查
			}
		}
	}
	
	/**
	 * 检查seekoffset版本号
	 */
	private function checkSeekOffsetVersion(){
		$currentSeekOffsetVer = $this->getSeekOffsetVersionVal();//获取当前seekoffset的版本号
		Kafka_Logger::info('check version currentSeekOffsetVer: '.$currentSeekOffsetVer. " old version: ".$this->seekOffsetVersion. " partitions: ".json_encode($this->partition_ids));
		if ($this->seekOffsetVersion < $currentSeekOffsetVer){
			if ($this->checkNewSeekOffset()){
				Kafka_Logger::info('commit trigger modify seekoffset version: '.$this->seekOffsetVersion. " to ".$currentSeekOffsetVer. " partitions: ".json_encode($this->partition_ids));
				$this->seekOffsetVersion = $currentSeekOffsetVer;
			}
		}
	}
}
