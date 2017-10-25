<?php

namespace Qbus3;
/**
 * Global configuration
 */
class Kafka_Config
{
    /**
     * @var   Int    sleeping microseconds in case of getting empty message from broker
     */
    public static $sleepMicroSec        = 1000000;

    /**
     * @var   Int     max try times in failure for one message
     */
    public static $maxTryTimes          = 1;

    /**
     * @var   Int     max process message number. if exceed this number, an exception will be thrown. 0 represent no limit
     */
    public static $maxProcessNum        = 0;

    /**
     * @var   Int     max process second. An exception will be thrown after running maxProcessSeconds. 0 means no limit
     */
    public static $maxProcessSeconds     = 0;

    /**
     * @var   Int     the tcp connection timeout to broker
     */
    public static $socketTimeout        = 3;

    /**
     * @var   Int     tcp socket buffer size
     */
    public static $socketBufferSize     = 4096;

    /**
     * @var   Int     max buffer size to fetch message from broker, it should be bigger than message length + 10 at least
     */
    public static $maxFetchSize         = 1000000;

    /**
     * @var   bool   if it is true, the consumed offset will be commit to zookeeper each time a message has been consumed
     *               if false, the offset will be commit after consuming a batch messages.
     */
    public static $singleOffsetCommit   = false;

    /**
     * $var Int the position when want offset not in broker
     * 0    consume from the offset can get
     * 1    consume from the newest
     */
    public static $consumePosition     = 0;

    public static $CommitIntevalCounts = 1000;

	#############################
	#####	No use		#####
	#####	this version	#####
    	/**
     	* @var Int     minimal interval(seconds) to poll zookeeper for the new consume configuration.
     	*/
    	public static $pollZKInterval       = 10;
	#############################

    public static $ClusterConfPath = "";
    
    public static $brokerCluster          = [];/* array(
	'test'  => '10.188.96.29:9092,10.138.104.216:9092,10.138.104.217:9092',
	'test1' => '10.138.104.216:9093',
	'test2' => '10.138.104.217:9092',
	
	'bjyt'  => '10.208.34.73:9092,10.208.34.74:9092,10.208.34.75:9092',
	'zzzc'  => "10.172.172.71:9092,10.172.172.72:9092,10.172.172.45:9092"
	    
    	//'bjdt'  => '106.38.193.181:9092',
       // 'zwt' => '10.108.79.180:2181,10.108.79.181:2181,10.108.79.182:2181',
       // 'hyb' => '10.118.99.253:2181,10.118.99.252:2181,10.118.99.251:2181',
       // 'shgt' => '10.115.111.253:2181,10.115.111.254:2181,10.115.111.252:2181',
       // 'njt' => '10.116.95.249:2181,10.116.95.250:2181,10.116.95.248:2181',
       // 'shht' => '10.120.91.251:2181,10.120.91.252:2181,10.120.91.250:2181',
       // 'vjc'  => '10.113.103.252:2181,10.113.103.253:2181,10.113.103.251:2181',
       // 'zzbc' => '10.119.135.253:2181,10.119.135.254:2181,10.119.135.252:2181',
       // 'zzbc2' => '10.119.255.97:2181,10.119.255.82:2181,10.119.255.83:2181,10.119.255.84:2181,10.119.255.85:2181',
       // 'nbt' => '10.123.87.6:2181,10.123.87.7:2181,10.123.87.8:2181',
       // 'shjc' => '10.125.199.29:2181,10.125.199.30:2181,10.125.199.31:2181',
       // 'shjc2' => '140.207.199.21:2181,140.207.199.22:2181,140.207.199.23:2181,140.207.199.24:2181,140.207.199.25:2181',
       // 'test' => '220.181.127.221:2181',
       // 'test2' => '10.102.74.52:2181',
       // 'test3' => '10.123.81.39:2181,10.123.81.43:2181,10.123.81.44:2181',
       // 'rtest' => '10.131.119.25:2181,10.131.119.26:2181,10.131.119.27:2181',
       // 'wenda' => '10.121.214.46:2181,10.121.214.47:2181,220.181.141.123:2182,10.108.214.31:2181,10.108.214.32:2181',
       // 'rbjsc' => '123.125.81.91:2181,123.125.81.92:2181,123.125.81.93:2181',
       // 'rzwt' => '103.28.8.25:2181,103.28.8.26:2181,103.28.8.27:2181,103.28.8.28:2181,103.28.8.29:2181',
       // 'bjdt' => '10.138.238.168:2181,10.138.238.169:2181,10.138.238.170:2181',
       // 'bjdt2' => '101.199.115.206:2181,101.199.115.207:2181,101.199.115.208:2181,101.199.115.213:2181,101.199.115.214:2181',
       // 'shct' => '10.140.112.33:2181,10.140.112.31:2181,10.140.112.29:2181',
       // 'bjcc' => '10.143.3.25:2181,10.143.3.24:2181,10.143.3.23:2181',
       // 'tyfc' => '10.137.112.39:2181,10.137.112.40:2181,10.137.112.41:2181',
       // 'tjhc' => '10.149.94.32:2181,10.149.94.33:2181,10.149.94.34:2181',
       // 'fszt' => '10.150.94.3:2181,10.150.94.5:2181,10.150.94.7:2181',
       // 'sjlc' => '10.151.95.21:2181,10.151.95.20:2181,10.151.95.19:2181',
       // 'txl_bjcc' => '10.143.6.61:2181,10.143.6.62:2181,10.143.6.63:2181',
       // 'njxt' => '10.152.95.9:2181,10.152.95.11:2181,10.152.95.12:2181',
       // 'lyct' => '10.161.54.18:2181,10.161.54.19:2181,10.161.54.20:2181',
       // 'hexc' => '10.153.91.199:2181,10.153.91.220:2181,10.153.91.221:2181',
       // 'whjt' => '10.154.96.202:2181,10.154.96.203:2181,10.154.96.204:2181',
       // 'zzct' => '10.122.80.85:2181,10.122.80.86:2181,10.122.80.87:2181,10.122.80.88:2181,10.119.135.26:2181',
       // 'xsp' => '10.155.80.104:2181,10.155.80.105:2181,10.155.80.106:2181',
       // 'bj' => '10.159.100.141:2181,10.159.100.142:2181,10.159.100.143:2181',
       // 'vnet' => '10.117.83.35:2181,10.117.83.36:2181,10.117.83.37:2181',
       // 'gzst2' => '125.88.200.140:2181,125.88.200.141:2181,125.88.200.142:2181,125.88.200.143:2181,125.88.200.144:2181',
       // 'zzzc2' => '10.172.170.139:2181,10.172.170.140:2181,10.172.170.141:2181,10.172.170.142:2181,10.172.170.143:2181',
    ); */
    
    public static $zkCluster          = [];/* array(
        'test1' => '10.138.104.216:2189',
	'test'=>'10.188.96.29:2181',
        'test2' => '10.138.104.217:2181',
        "bjyt"  => "10.208.34.73:2181,10.208.34.74:2181,10.208.34.75:2181",
        "zzzc"  => "10.172.172.71:2181,10.172.172.72:2181,10.172.172.45:2181"
    ); */
    
    public static function getZkCluster($cluster_name = "") 
    {
        if (empty(self::$zkCluster)){
            self::$zkCluster = self::getConf();
        }
        if ($cluster_name){
            return empty(self::$zkCluster[$cluster_name]) ? "" : self::$zkCluster[$cluster_name];
        }else return self::$zkCluster;
    }
    
    public static function getBrokerCluster($cluster_name) 
    {
        if (empty(self::$brokerCluster)){
            self::$brokerCluster = self::getConf('broker');
        }
        if ($cluster_name)
        return empty(self::$brokerCluster[$cluster_name]) ? "" : self::$brokerCluster[$cluster_name];
    }
    
    public static function getConf($type='zk') 
    {
        $node_name = $type == 'zk' ? 'zookeeper' : 'kafka';
        if (empty(self::$ClusterConfPath)){
        	self::$ClusterConfPath = file_get_contents(__DIR__."/cluster.dat");
        }
        $config = json_decode(self::$ClusterConfPath, true);
        $conf = [];
        if ($config){
            foreach ($config as $cluster_name => $addr) {
                $conf[$cluster_name] = $addr[$node_name];
            }
        }
        return $conf;
    }
}
