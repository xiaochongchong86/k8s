<?php

namespace Utils;
use Qbus3\Kafka_Logger;

/**
 * Utils used by kafka client to communicate with zookeeper 
 */
class ZkUtil
{
    const consumer_dir    = '/consumers';
    const broker_ids_dir   = '/brokers/ids';
    const broker_topics_dir = '/brokers/topics';
    private static $callback = array();
    /**
     * default acl whening creating a zonde in zookeeper
     */
    static $acl = array(
        array('perms' => 0x1f, 'scheme' => 'world','id' => 'anyone')
    );
    
    private static function getPartitionPath($topic)
    {
    	return self::broker_topics_dir."/{$topic}/partitions";
    }
    
    public static function getConsumerPath($topic, $group)
    {
    	return self::consumer_dir."/{$topic}/{$group}";
    }
    
    public static function getOffsetPath($topic, $group){
    	return self::consumer_dir."/{$topic}/{$group}/offset";
    }
    
    public static function getOffsetVsersionPath($topic, $group){
    	return self::consumer_dir."/{$topic}/{$group}/offsetversion";
    }
    
    /**
     * get globle consemer seek offset
     * @param unknown $zk
     * @param unknown $topic
     * @param unknown $group
     * @return mixed
     */
    public static function getGloblePartSeekOffsetMap($zk, $topic, $group){
    	$path = self::getOffsetPath($topic, $group);
    	$seekOffset = [];
    	if ($zk->exists($path)){
    		$seekOffset = $zk->get($path);
    		if ($seekOffset){
    			$seekOffset = json_decode($seekOffset, true);
    		}
    	}else{
    		self::createPersistent($zk, $path, "{}");
    	}
    	return $seekOffset;
    }
    
    /**
     * @param unknown $zk
     * @return brokerMap["brokerId"] = ip:port
     */
    public static function getBrokersMap($zk)
    {
    	 $path = self::broker_ids_dir;
    	 $brokerIds = $zk->getChildren($path);
    	 $brokerMap = [];
    	 if ($brokerIds){
    	 	foreach ($brokerIds as $id){
    	 		$info = json_decode($zk->get("{$path}/{$id}"), true);
    	 		if (!empty($info['host']) && !empty($info['port'])){
    	 			$brokerMap[$id] = "{$info['host']}:{$info['port']}";
    	 		}
    	 	}
    	 }
    	 return $brokerMap;
    }
    
    /**
     * @param unknown $zk
     * @param unknown $topic
     * @return partition['partitionId'] = "leaderId";
     */
    public static function getPartitionsMap($zk, $topic)
    {
    	$path = self::getPartitionPath($topic);
    	$partitionIds = $zk->getChildren($path);
    	$partitionMap = [];
    	if ($partitionIds){
    		foreach ($partitionIds as $id){
    			$info = json_decode($zk->get("{$path}/{$id}/state"), true);
    			if (isset($info['leader'])){
    				$partitionMap[$id] = $info['leader'];
    			}
    		}
    	}
    	return $partitionMap;
    }
    
    /**
     * @param unknown $zk
     * @param unknown $topic
     * @param unknown $group
     * @return consumerMap['consumer-name'] = ["partitionid1","p2"]
     */
    public static function getConsumersMap($zk, $topic, $group)
    {
    	$path = self::getConsumerPath($topic, $group);
    	if (!$zk->exists($path)){
    		return [];
    	}
    	$conmers = $zk->getChildren($path);
    	$conmerMap = [];
    	if ($conmers){
    		foreach ($conmers as $name) {
    			if ($name == 'offset') continue;
    			$info = json_decode($zk->get("{$path}/{$name}"), true);
    			$conmerMap[$name] = $info;
    		}
    	}
    	return $conmerMap;
    }
    
    public static function getConsumerName()
    {
    	$sysinfo = posix_uname();
    	$cmd = <<<CMD
    	ifconfig | grep 'addr:' | grep '10.' | awk 'BEGIN{FS=":"} {print $2}'| awk 'BEGIN{FS=" "} {print $1}'
CMD;
    	exec($cmd, $out, $ret_var);
    	$ip = "";
    	if ($out){
    		if ($ret_var === 0){
    			$ip = isset($out[0]) ? $out[0] : "";
    		}
    	}
    	return "{$sysinfo['nodename']}_{$ip}_".getmypid();
    }
    
    /**
     * 注册consumer pid and partitions
     * @param unknown $zkClient
     * @param unknown $topic
     * @param unknown $group
     * @param array $partitions
     * @param unknown $consumer_name
     * @return boolean
     */
    public static function createConsumerPid($zkClient, $topic, $group, array $partitions, $consumer_name)
    {
    	$path = self::getConsumerPath($topic, $group)."/{$consumer_name}";
    	$partitions = json_encode($partitions);
    	if (!$zkClient->exists($path)){
	    	if (!self::createEphemeralPath($zkClient, $path, $partitions)){
	    		Kafka_Logger::warn("create consumer pid and partition: {$partitions} to path:$path fail");
	    		return false;
	    	}else {
	    		Kafka_Logger::info("create consumer pid and partition: {$partitions} to path:$path suc");
	    		return true;
	    	}
    	}else {
    		if ($zkClient->set($path, $partitions)){
    			Kafka_Logger::info("up consumer pid and partition: {$partitions} to path:$path suc");
    		}else {
    			Kafka_Logger::info("up consumer pid and partition: {$partitions} to path:$path fail");
    		}
    	}
    }
    
    /**
     * pop consumer partitions
     * @param unknown $zkClient
     * @param unknown $topic
     * @param unknown $group
     * @param array $partitions
     * @param unknown $consumer_name
     * @return boolean
     */
    public static function popConsumerPartIds($zkClient, $topic, $group, array $partitions, $consumer_name)
    {
    	$path = self::getConsumerPath($topic, $group)."/{$consumer_name}";
    	if ($zkClient->exists($path)){
    		$partitions_old = json_decode($zkClient->get($path), true);
    		$new_part = json_encode(array_values(array_diff($partitions_old, $partitions)));
    		if ($zkClient->set($path, $new_part)){
    			Kafka_Logger::info("pop consumer pid to path:$path old_part: ".implode("-", $partitions_old).
    					", pop_part: ".implode("-", $partitions)." new_part: {$new_part} suc");
    			return true;
    		}
    	}else {
    		Kafka_Logger::info("pop consumer pid to path:$path oldpart: ".implode("-", $partitions_old).
    				", popPart: ".implode("-", $partitions)." fial");
    		return false;
    	}
    }
    
    /**
     * Create a ephemeral znode in zookeeper. If parent node doesn't exists, it will be created with null data
     * @var Object  $zkClient       zookeeper instance
     * @var String  $path           znode path
     * @var String  $groupId        znode data
     * @return true or false
     */
    static public function createEphemeralPath($zkClient, $path, $data) 
    {
        if (self::createEphemeral($zkClient, $path, $data) == false)
        {
            self::createParentPath($zkClient, $path);
            return self::createEphemeral($zkClient, $path, $data);
        }
        return true;
    }
    
    public static function assignPartitionTokenPath($topic, $group) {
    	return self::getConsumerPath($topic, $group)."/token_".getmypid();
    }
    
    public static function lock($zkClient, $path)
    {
    	return self::createEphemeralPath($zkClient, $path, "");
    }
    
    public static function unlock($zkClient, $path)
    {
    	return $zkClient->delete($path);
    }
	
    /**
     * Create a ephemeral znode in zookeeper. 
     * @var Object  $zkClient       zookeeper instance
     * @var String  $path           znode path
     * @var String  $groupId        znode data
     * @return true or false
     */
    static public function createEphemeral($zkClient, $path, $data) 
    {
        if (!$zkClient->exists($path))
        {
            return @$zkClient->create($path, $data, self::$acl, \Zookeeper::EPHEMERAL);
        }
        return false;
    }

    /**
     * Create a persistent znode in zookeeper. 
     * @var Object  $zkClient       zookeeper instance
     * @var String  $path           znode path
     * @var String  $groupId        znode data
     * @return true or false
     */
    static public function createPersistent($zkClient, $path, $data) 
    {
        return $zkClient->create($path, $data, self::$acl);
    }

    /**
     * Create the parent znodes in zookeeper if it doesn't exists, not including the last znode
     * @var Object  $zkClient       zookeeper instance
     * @var String  $path           znode path
     * @return true or false
     */
    static public function createParentPath($zkClient, $path) 
    {
        $dirs = explode('/', $path);
        //delele tha last znode
        array_pop($dirs);
        $path = '';
        foreach ($dirs as $dir)
        {
            if ($dir === "") continue; 
            $path = "$path/$dir";
            if (@$zkClient->exists($path) === false)
            {
                self::createPersistent($zkClient, $path, '');
            }
        }
    }
    
    /**
     * Wath a given path
     * @param string $path the path to node
     * @param callable $callback callback function
     * @return string|null
     */
    public static function watch($zk, $path, $callback)
    {
    	if (!is_callable($callback)) {
    		return null;
    	}
    
    	if ($zk->exists($path)) {
    		if (!isset(ZkUtils::$callback[$path])) {
    			ZkUtils::$callback[$path] = array();
    		}
    		if (!in_array($callback, ZkUtils::$callback[$path])) {
    			ZkUtils::$callback[$path][] = $callback;
    			return $zk->get($path, 'ZkUtils::watchCallback');
    		}
    	}
    }
    
    /**
     * Wath event callback warper
     * @param int $event_type
     * @param int $stat
     * @param string $path
     * @return the return of the callback or null
     */
    public static function watchCallback($zk, $event_type, $stat, $path)
    {
    	if (!isset(ZkUtils::$callback[$path])) {
    		return null;
    	}
    
    	foreach (ZkUtils::$callback[$path] as $callback) {
    		$zk->get($path, 'ZkUtils::watchCallback');
    		return call_user_func($callback);
    	}
    }
    
    /**
     * Delete watch callback on a node, delete all callback when $callback is null
     * @param string $path
     * @param callable $callback
     * @return boolean|NULL
     */
    public function cancelWatch($zk, $path, $callback = null)
    {
    	if (isset(ZkUtils::$callback[$path])) {
    		if (empty($callback)) {
    			unset(ZkUtils::$callback[$path]);
    			$zk->get($path); //reset the callback
    			return true;
    		} else {
    			$key = array_search($callback, ZkUtils::$callback[$path]);
    			if ($key !== false) {
    				unset(ZkUtils::$callback[$path][$key]);
    				return true;
    			} else {
    				return null;
    			}
    		}
    	} else {
    		return null;
    	}
    }

    static public function setLogStream($stream)
    {
        if (class_exists('Zookeeper')){
            $zk = new \Zookeeper();
            return $zk->setLogStream($stream);
        }else{
            return false;
        }
    }
}
