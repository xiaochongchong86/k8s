<?php
spl_autoload_register("kafka_autoload3");

function kafka_autoload3($classname)
{
    $classpath = kafka_getClassPath3();
    if (isset($classpath[$classname])) {
        include ($classpath[$classname]);
    }
}

function kafka_getClassPath3()
{
    static $classpath = array();
    if (! empty($classpath))
        return $classpath;
    else {
        $classpath = array(
            "Qbus3\Kafka_Config" => "Kafka/Config.php",
            "Qbus3\Kafka_ConstDef" => "Kafka/ConstDef.php",
            "Qbus3\Kafka_Consumer" => "Kafka/Consumer.php",
            "Qbus3\Kafka_Logger" => "Kafka/Logger.php",
            "Qbus3\Kafka_Producer" => "Kafka/Producer.php",
            "File" => "build_includes.php",
            "AssemblyBuilder" => "build_includes.php",
            "Utils\ZookeeperC" => "ZookeeperC.php",
        	"Utils\ZkUtil" => "ZkUtil.php"
        );
    }
    return $classpath;
}
if (function_exists("__autoload")) {
    spl_autoload_register("__autoload");
}
?>
