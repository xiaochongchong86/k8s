<?php


namespace Qbus3;

/**
 * Logger for Kafka.
 *
 */

class Kafka_Logger
{
    private static $logPath    = '';
    private static $logKeyword = 'KafkaClient';

    public static function init($logPath, $logKeyword = 'KafkaClient')
    {
        self::$logPath      = $logPath;
        self::$logKeyword   = $logKeyword;
    }

	public static function info($msg) {
		$msg = 'INFO ['.date("Y-m-d H:i:s").']  '.$msg."\n";
		return file_put_contents(self::getLogFile('info'), $msg, FILE_APPEND);
	}
	
	public static function warn($msg) {
		$msg = 'WARN ['.date("Y-m-d H:i:s").']  '.$msg."\n";
		return file_put_contents(self::getLogFile('warn'), $msg, FILE_APPEND);
	}
	
	public static function error($msg, $code = 0) {
		$msg = 'ERROR ['.date("Y-m-d H:i:s").']  '.$msg."\n";
		return file_put_contents(self::getLogFile('error'), $msg, FILE_APPEND);
	}

	public static function logOffset($topic, $groupId, $brokerId, $partition, $offset) {
		$msg = date("Y-m-d H:i:s")." $topic $groupId $brokerId $partition $offset\n";
		return file_put_contents(self::getLogFile('info'), $msg, FILE_APPEND);
	}

	public static function logSingalMsgOffset($topic, $groupId, $brokerId, $partition, $offset) {
		$msg = date("Y-m-d H:i:s")." $topic $groupId $brokerId $partition $offset\n";
		return file_put_contents(self::getLogFile('info'), $msg, FILE_APPEND);
	}

	public static function logFetchOffset($topic, $groupId, $brokerId, $partition, $offset) {
		$msg = date("Y-m-d H:i:s")." $topic $groupId $brokerId $partition $offset\n";
		return file_put_contents(self::getLogFile('info'), $msg, FILE_APPEND);
	}

    public static function getLogFile($type)
    {
        if (!self::$logPath)
        {
            self::$logPath = dirname(__FILE__).'/../../logs';
        }
        if($type == 'info') {
            $file = self::$logPath.'/info-log.' . date("Ymd");
        } else if($type == 'warn') {
            $file = self::$logPath.'/warn-log.' . date("Ymd");
        } else if ($type == 'error') {
            $file = self::$logPath.'/error-log.' . date("Ymd");
        } else {
            $file = self::$logPath.'/default-log.' . date("Ymd");
        }
        if (!is_file($file)) {
            touch($file);
            @chmod($file, 0777);
        }
        return $file;
    }

}

?>
