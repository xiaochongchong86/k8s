#!/bin/sh

agent=qconf_agent                                     
#cmdfile=/usr/local/qconf-agent/cmd/cmd$$            	#file used to send command for agent
#pidfile=/usr/local/qconf-agent/pid                  	#file restroe the current agent deamon thread

cmdfile=cmd/cmd$$            	#file used to send command for agent
pidfile=pid                  	#file restroe the current agent deamon thread
resultfile=result/result$$   	#result file end with pid of this shell
#resultfile=/usr/local/qconf-agent/result/result$$   	#result file end with pid of this shell
agentpath=./qconf_agent

chdpid=$(cat $pidfile)   				#file store thread id for current agent deamon who in charge for command processing
exist=$(ps -A | grep -w $agent | grep -w $chdpid)    	#whether the agent is alive

command_to_agent=""    					#command which will be send to agent


show_usage_and_exit () {             			#show usage and exit
    echo "Usage: "
    echo "  $0 start                                         start qconf agent."
    echo "  $0 restart                                       restart qconf agent."
    echo "  $0 stop                                          stop qconf agent."
    echo "  $0 info                                          show information of agent."
    echo "  $0 list-all                                      get the whole nodes in share memory."
    echo "  $0 clear-all                                     clear the whole nodes in share memory."
    echo "  $0 stop_listen HOST                              stop listening to HOST. "
    echo "  $0 restart_listen HOST                           restart to listen to HOST."
    echo "  $0 ls host path                                  list nodes."
    echo "  $0 delete -h HOST -p PATH...                     delete node with path."
    echo "  $0 get -h HOST -p PATH...                        get value of paths."
    echo "  $0 create -h HOST -p PATH... -v VALUE            create node with path and set its value."
    echo "  $0 set -h HOST -p PATH... -v VALUE               set node value by path."
    echo "  $0 serve_add -h HOST -p PATH -v VALUE...         add services on PATH of HOST."
    echo "  $0 serve_delete -h HOST -p PATH -v VALUE...      delete services on PATH of HOST."
	exit 1
}




arg_parsing_noval () {					#argument parsing for delete and get command

    
    host=""
    path_str=""
    value_str=""
	if [ $# -lt 5 ] ;then
	   echo "Parameter count error!"
       show_usage_and_exit	
   fi
	para_num=0
    para_switch=""   					#indicate current state  
	for para in $@
	do
        ((para_num++))
        if [ $para_num -lt 2 ]; then
            continue
        fi
		case $para in
            "-h")
                para_switch="host"
                ;;
            "-p")
                para_switch="paths"
                ;;
           *)
            case $para_switch in
                "host")
                    host=$para
                    para_switch=""
                    ;;
                "paths")
                    path_str=${path_str}$para\;
                    ;;
                "")
                    echo "Parameter Error!"
                    show_usage_and_exit
                    ;;
            esac
            ;;
        esac
	done

    if [ "$host" = "" ] || [ "$path_str" = "" ]; then	#if miss host or path error
        echo "Parameter Error!"
        show_usage_and_exit
        fi

    command_to_agent="$1#$host#$path_str#" 		#concat command which will be send to agent

}



arg_parsing_serve () {					#argument parsing for serve_add and serve_delete
    
    host=""
    path_str=""
    value_str=""
    if [ $# -lt 7 ] ;then
	   echo "Parameter count error!"
	   show_usage_and_exit
	fi
	para_num=0
    	para_switch=""   				#indicate current state  
	for para in $@
	do
        ((para_num++))
        if [ $para_num -lt 2 ]; then
            continue
        fi
		case $para in
            "-h")
                para_switch="host"
                ;;
            "-p")
                para_switch="paths"
                ;;
            "-v")
                para_switch="value"
                ;;
           *)
            case $para_switch in
                "host")
                    host=$para
                    para_switch=""
                    ;;
                "paths")
                    path_str=$para
                    para_switch=""
                    ;;
                "value")
                    value_str=${value_str}$para\;
                    ;;
                "")
                    echo "Parameter Error!"
                    show_usage_and_exit
                    ;;
            esac
            ;;
        esac
	done

    
    if [ "$host" = "" ] || [ "$path_str" = "" ] || [ "$value_str" = "" ]; then		#if miss host or path error
        echo "Parameter Error!"
        show_usage_and_exit
    fi
    
    command_to_agent="$1#$host#$path_str#$value_str#" 					#concat command which will be send to agent
}



arg_parsing_val () {					#argument parsing for create and set
	
    host=""
    path_str=""
    value_str=""
    if [ $# -lt 7 ] ;then
	   echo "Parameter count error!"
        show_usage_and_exit
	fi
	para_num=0
    para_switch=""   					#indicate current state  
	for para in $@
	do
        # echo "para is $para"
        ((para_num++))
        if [ $para_num -lt 2 ]; then  			#skip the first parameter
            continue
        fi
        

		case $para in
            "-h")
                para_switch="host"
                ;;
            "-p")
                para_switch="paths"
                ;;
            "-v")
                para_switch="value"
                ;;
            *)
            case $para_switch in
                "host")
                    host=$para
                    para_switch=""
                    ;;
                "paths")
                    path_str=${path_str}$para\;
                    ;;
                "value")
                    value_str=$para
                    para_switch=""
                    ;;
                "")
                    echo "Parameter Error!"
                    show_usage_and_exit
                    ;;
            esac
            ;;
        esac
	done


    if [ "$host" = "" ] || [ "$path_str" = "" ] || [ "$value_str" = "" ]; then
        echo "Parameter Error!"
        show_usage_and_exit
    fi

    command_to_agent="$1#$host#$path_str#$value_str#" 	#concat command which will be send to agent
}



wait_process () {					#wait for the process result from agent
    while [ ! -f "$resultfile" ]
    do
        sleep 0.2s
    done
    #echo "Result path for $$ has been found!"
    #line=${head 1 $resultpath}
    #tail -"$line" $resultfile

    #line=${wc l $resultfile}
    tail -n 2 $resultfile
    rm -f "$resultfile"
}


create_cmdfile () {					#create cmd file to send command to agent
    if [ ! -f "$cmdfile" ]; then
        touch "$cmdfile"
    fi
}


chk_agent_exist () {
    if [ "$exist" = "" ]; then
        echo "$agent is not running."
        show_usage_and_exit
    fi
}



start () {
    if [ "$exist" = "" ]; then
        $agentpath
        echo "$agent start."
    else
        echo "$agent is already running"
        show_usage_and_exit
    fi
}


restart () {
    chk_agent_exist
    kill -s USR2 $chdpid
}


stop () {
    chk_agent_exist
    killall -9 $agent
    echo "$agent stop."
}


common_arg_parsing () {
case "$1" in
    "info")
	if [ $# -ne 1 ]; then
	    show_usage_and_exit $*
	fi
	command_to_agent="$1#"
    ;;
    "list-all")
    if [[ $# -ne 1 ]]; then
        show_usage_and_exit $*
    fi
    command_to_agent="$1#"
    ;;
    "clear-all")
    if [[ $# -ne 1 ]]; then
        show_usage_and_exit $*
    fi
    command_to_agent="$1#"
    ;;
    "stop_listen")
        if [ $# -ne 2 ]; then
            show_usage_and_exit $*
        fi
        command_to_agent="$1#$2#"            
    ;;

    "restart_listen")
        if [ $# -ne 2 ]; then
            show_usage_and_exit
        fi
        command_to_agent="$1#$2#"
    ;;
    
    "ls")
        if [ $# -ne 3 ]; then
            show_usage_and_exit
        fi
        command_to_agent="$1#$2#$3#"
    ;;

    "delete")
        arg_parsing_noval $*
    ;;

    "get")
        arg_parsing_noval $*
    ;;

    "create")
	    arg_parsing_val $*
	;;


    "set")
        arg_parsing_val $*
    ;;
    
    "serve_add")
        arg_parsing_serve $*
    ;;

    "serve_delete")
        arg_parsing_serve $*
    ;;
    *)
        show_usage_and_exit
    ;;
esac
}


send_signal () {
	if [ ! -f "$pidfile" ]; then
		echo "can not connect with agent, please wait and try again!" ; exit 1; 
	fi
	kill -USR1 $chdpid
    if [[ $? != 0 ]]; then
        echo "cmd 'kill -USR1 $chdpid' exec failed!"
        exit -1
    fi
	echo "Send $1 to $agent"
}


#common process function
common_process () {
    chk_agent_exist  					#check whether the agent is running
    common_arg_parsing $*   				#parsing argument
    create_cmdfile   					#create cmdfile
    #echo "$command_to_agent"
    echo "$command_to_agent" >$cmdfile   		#write cmdfile
    send_signal $1
    wait_process
}



(
flock -n -e 200 ||{ echo "instance already exist, please wait and try later!" ; exit 1 ; }

#Entry
if [ "$1" == "stop" ]; then
    stop
elif [ "$1" == "start" ]; then
    start
elif [ "$1" == "restart" ]; then
    restart
else
    common_process $*
fi

)200>lock/lockfile

 
