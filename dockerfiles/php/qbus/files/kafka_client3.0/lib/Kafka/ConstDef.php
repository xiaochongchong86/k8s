<?php

namespace Qbus3;
/**
 * common const
 */
class Kafka_ConstDef
{
    const KAFKA_VERSION             = 'kafka_client-0.1.3';  //kafka client version, for sdk version statistic

    const INVALID_OFFSET            = -1;    //invalid offset

    const ERROR_INVALID_FETCH_SIZE  = 0xFabc;  //invlid fetch size or fetch offset

    const ERROR_INIT_CONSUMER_FAILED= 0xF001;  //initiate kafka consumer failed

    const EXCEPTION_NEED_EXIT       = 0xF007;  //got exit command from zookeeper or run out of time quota

    const ERROR_CANNOT_SEND_REQUEST = 0x0002;  //cann't send request to broker,may lost connection

    const EXCEPTION_THROW_TO_USER   = 0x8000;  //exception throw to user. if exception errno set this bit,it will be throw to sdk user, otherwise we catch and consume it

    const EXCEPTION_FATAL_ERROR     = 0xF004;  //in case of this exception, we need to exit

    const EXCEPTION_SOCKET_ERROR    = 0x0003;  //socket stream error

    const MESSAGE_RANDOM_SEND       = 1;     //random send to one of the available broker
    const MESSAGE_AFFINITY_SEND     = 2;     //always send to one broker each topic, if the broker down, then it will choose to other broker
    const MESSAGE_SEMANTIC_SEND     = 3;     //selected partitions by a key, the same key's messages will be send to the same partition

    const RANDON_PARTITION          = -1;     //selected partitions by a key, the same key's messages will be send to the same partition

    const ERROR_ZK_OP               = 0x0011;     //operate zookeeper failed, maybe network reason
    const ERROR_OFFSET              = 0x0012;     //get wrong offset from zookeeper
    const ERROR_INVALID_MSG         = 0x0013;     //invalid msg for wrong checksum
    const ERROR_CONNECTION          = 0x0014;     //connect to server failed
    const ERROR_ENCODE_MSG          = 0x0015;     //encode message failed
    const ERROR_GET_FLOCK           = 0x0016;     //get file lock failed when sending message
    const ERROR_WRITE_FILE          = 0x0017;     //write file failed when sending message

    const MESSAGE_BOUNDARY_MAGIC    = 0x5e5c7cfe;  //magic value for asyncSend message boundary

    const MESSAGE_VERSION           = 0x01;     //asyncSend message version number 
    
    const SEQUENCE_MESSAGE_VERSION  = 0x02;     //asyncSend message version number 

    const CLUSTER_DATA_PREFIX       =  '/home/syncops/software/kafka_agent/local_logs/msg_file.';   //dir to save messages sent by local sdk
}
