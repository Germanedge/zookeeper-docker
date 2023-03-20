#!/bin/bash

if [[ -f ${ZK_HOME}/conf/log4j.properties ]]; then
	sed -i -r 's|#(log4j.appender.ROLLINGFILE.MaxBackupIndex.*)|\1|g' $ZK_HOME/conf/log4j.properties
	sed -i -r 's|(zookeeper.root.logger=.*)|\1, ROLLINGFILE|g' $ZK_HOME/conf/log4j.properties
	sed -i -r 's|(zookeeper.log.maxfilesize=.*)|zookeeper.log.maxfilesize=16MB|g' $ZK_HOME/conf/log4j.properties
fi

sed -i -r 's|#metricsProvider|metricsProvider|g' $ZK_HOME/conf/zoo.cfg
sed -i -r 's|#autopurge|autopurge|g' $ZK_HOME/conf/zoo.cfg

export ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"
export ZOO_LOG_DIR="/app/logs"

current_uid=$(stat -c "%u" ${ZK_HOME}"/data")
current_gid=$(stat -c "%g" ${ZK_HOME}"/data")

if [[ ${current_uid} != 1000 ]] || [[ ${current_gid} != 1000 ]]; then
        cat <<EOF
        ********************************************************************************
            BREAKING CHANGE: Data files are inaccessable! 
                            
                             For newer versions of zookeeper (>= 4.0.0), all data files 
                             (/opt/zookeeper/data) must be owned by 1000:1000.
                             
                             Currently they are owned by ${current_uid}:${current_gid}.

                             To set the correct ownership, please edit the zookeeper
                             deployment and use the image zookeeper:3.93.0

                             When you see the following messages in the logs...

                             [Edge.One][*** MIGRATION START ***] Change ownership of 
                               zookeeper data files.
                             [Edge.One][*** MIGRATION END ***] Change ownership of 
                               zookeeper files finished.

                             ... you can re-edit the zookeeper deployment and set it to 
                             the latest version.

                             The container will continue to run.
        ********************************************************************************
EOF
    while true; do
      sleep 500
    done
fi

/opt/zookeeper/bin/zkServer.sh start-foreground
