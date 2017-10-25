<?php
/**
 * Utils used by kafka client to communicate with zookeeper 
 */
class ZkUtils
{
    //const consume_info_dir = '/consume_info';
    const consumer_dir    = '/consumers';
    const broker_ids_dir   = '/brokers/ids';
    const broker_topics_dir = '/brokers/topics';

    /**
     * default acl whening creating a zonde in zookeeper
     */
    static $acl = array(
        array('perms' => 0x1f, 'scheme' => 'world','id' => 'anyone')
    );
    
    static public function createConsumerPid($zkClient, $topic, $group)
    {
        $sysinfo = posix_uname();
        // /consumers/topic/group/hostname_ip_pid => ip
        exec("nslookup {$sysinfo['nodename']} | grep Address: | grep -v '#'", $out, $ret_var);
        $ip = "";
        if ($out){
            if ($ret_var === 0){
                $ipc = explode(": ", $out[0]);
                $ip = isset($ipc[1]) ? $ipc[1] : "";
            }
        }
        $path = self::consumer_dir."/{$topic}/{$group}/{$sysinfo['nodename']}_{$ip}_".getmypid();
        if (!self::createEphemeralPath($zkClient, $path, $ip)){
            Kafka_Logger::warn("create consumer pid to path:$path fail");
            return false;
        }else {
            Kafka_Logger::info("create consumer pid to path:$path suc");
            return true;
        }
    }
    
    /**
     * commit offset to zookeeper
     *
     * @var Object  $zkClient       zookeeper instance
     * @var String  $topic          topic
     * @var String  $groupId        consumer group Id
     * @var Int     $BrokerId       broker id
     * @var Int     $partition      partition
     * @var Int     $offset         consumed msg offset in one partition
     * $return true or false
     */
    static public function commitOffset($zkClient, $topic, $groupId, $brokerId, $partition, $offset) 
    {
        $path = self::consumer_dir."/$topic/$groupId/offsets/$brokerId-$partition";
        return $zkClient->set($path, $offset);
    }

    /**
     * Get a partition's message offset from zookeeper
     *
     * @var Object  $zkClient       zookeeper instance
     * @var String  $topic          topic
     * @var String  $groupId        consumer group Id
     * @var Int     $BrokerId       broker id
     * @var Int     $partition      partition
     * @return Int offset
     */
    static public function getOffset($zkClient, $topic, $groupId, $brokerId, $partition) 
    {
        $path   = self::consumer_dir."/$topic/$groupId/offsets/$brokerId-$partition";
        if($zkClient->exists($path))
        {
            return $zkClient->get($path);
        }
        else
        {
            //for the first time, we need to create it and initiate to zero
            self::createParentPath($zkClient, $path);   
            self::createPersistent($zkClient, $path, 0);
            return 0;
        }
    }

    static public function getPartitionNum($zkClient, $topic, $brokerId) 
    {
        
        $path   = self::broker_topics_dir."/$topic/$brokerId";
        $data   = @$zkClient->get($path);
        return $data === null ? 1 : $data;
    }

    /**
     * After the consumer starting up ,we should tell zookeeper the consumer ID and group ID, and which topic to consume
     */
    static public function registerConsumeInfo($zkClient, $topic, $groupId, $consumerId) 
    {
        $path = self::consumer_dir."/$topic/$groupId/ids/$consumerId";
        self::createEphemeralPath($zkClient, $path, '');
        return @$zkClient->exists($path);
    }

    /**
     * Release the ownership of a partition by deleting the corresponding zookeeper node
     */
    static public function releasePartitionOwnership($zkClient, $topic, $groupId, $brokerId, $partition, $consumerId) 
    {
        $path       = self::consumer_dir."/$topic/$groupId/owners/$brokerId-$partition";
        $occupant   = $zkClient->get($path);
        if ($occupant === $consumerId || empty($occupant))
        {
            $ret = $zkClient->delete($path);   //delete it anyway
            return empty($occupant) ? true : $ret;
        }
        else
        {
            Kafka_Logger::warn("release other consumer's partition! topic:$topic groupId:$groupId brokerid:$brokerId partition:$partition consumerid:$consumerId original consumer:$occupant");
            return false;
        }
    }

    /**
     * Register partition ownership in zookeeper
     * @return true or false
     */
    static public function registerPartitionOwnership($zkClient, $topic, $groupId, $brokerId, $partition, $consumerId) 
    {
        $path = self::consumer_dir."/$topic/$groupId/owners/$brokerId-$partition";
        if ($zkClient->exists($path))
        {
            $occupant = $zkClient->get($path);
            if ($occupant === $consumerId)
            {
                return true;
            }
            else
            {
                Kafka_Logger::warn("register partition ownership failed! topic:$topic groupId:$groupId brokerid:$brokerId partition:$partition consumerid:$consumerId original consumer:$occupant");
                return false;
            }
        }
        return self::createEphemeralPath($zkClient, $path, $consumerId);
    }

    /**
     * Get the consuming configuration in zookeeper, the configuration tell which partitions need to consume
     */
    static public function getConsumeInfo($zkClient, $topic, $groupId, $consumerId, &$stat = null) 
    {
        $path = self::consumer_dir."/$topic/$groupId/ids/$consumerId";
        return @$zkClient->get($path, null, $stat);
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

    /**
     * Create a ephemeral znode in zookeeper. 
     * @var Object  $zkClient       zookeeper instance
     * @var String  $path           znode path
     * @var String  $groupId        znode data
     * @return true or false
     */
    static public function createEphemeral($zkClient, $path, $data) 
    {
        if (!@$zkClient->exists($path))
        {
            return @$zkClient->create($path, $data, self::$acl, Zookeeper::EPHEMERAL);
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
            if (empty($dir)) continue; 
            $path = "$path/$dir";
            if (@$zkClient->exists($path) === false)
            {
                self::createPersistent($zkClient, $path, '');
            }
        }
    }

    /**
     * Get all the brokers id on zookeeper
     */
    static public function getAllBrokersId($zkClient)
    {
        $brokers = array();
        $brokers = @$zkClient->getChildren(self::broker_ids_dir);
        return $brokers;
    }

    /**
     * Given a broker's ID, return it's ip and port
     * @var Object      $zkClient  zookeeper instance
     * @var Int         $brokerId  broker's ID
     * return  Array(IP, port)
     */
    static public function getBrokerIPAndPort($zkClient, $brokerId) 
    {
        $path = self::broker_ids_dir . "/$brokerId";
        $brokerInfo = $zkClient->get($path);
        if (!empty($brokerInfo))
        {
            $infos = explode(':', $brokerInfo);
            return array($infos[1], $infos[2]);
        }
        return array(null,null);
    }

    /**
     *  Check whether a znode is exists
     *  @return true or false
     */
    static public function existsPath($zkClient, $path) 
    {
        return $zkClient->exists($path);
    }

    /**
     *  从zookeeper上取得需要设置的消费offset,当consumer设置好新的offset，需要主动在zookeeper上删除这个信息，以防下次再被重新设置
     */
    static public function getNewOffset($zkClient, $topic, $groupId)
    {
        $offsets = array();
        $path = self::consumer_dir."/$topic/$groupId/newoffset";
        $partitionNewOffset = @$zkClient->getChildren($path);
        if (!empty($partitionNewOffset))
        {
            foreach ($partitionNewOffset as $partition)
            {
                $offsetPath = "$path/$partition";
                $offset = $zkClient->get($offsetPath);
                $offsets[$partition] = $offset;
            }
        }
        return $offsets;
    }

    /**
     * 操作成功后，需要在zookeeper上删除该节点，以防下次再被重新设置
     */
    static public function setNewOffsetSucc($zkClient, $topic, $groupId, $partition)
    {
        $path = self::consumer_dir."/$topic/$groupId/newoffset/$partition";
        $zkClient->delete($path);
    }

    /**
     * 将zookeeper的日志重定向，每个程序只需要调用一次
     */
    static public function setLogStream($stream)
    {
        if (class_exists('Zookeeper')){
            $zk = new Zookeeper();
            return $zk->setLogStream($stream);
        }else{
            //如果是异步发送，不需要zookeeper
            return false;
        }
    }
}
