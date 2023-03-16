#!/bin/sh	

sed -i -r 's|#(log4j.appender.ROLLINGFILE.MaxBackupIndex.*)|\1|g' $ZK_HOME/conf/log4j.properties
sed -i -r 's|#autopurge|autopurge|g' $ZK_HOME/conf/zoo.cfg
sed -i -r 's|(zookeeper.root.logger=.*)|\1, ROLLINGFILE|g' $ZK_HOME/conf/log4j.properties
sed -i -r 's|(zookeeper.log.maxfilesize=.*)|zookeeper.log.maxfilesize=16MB|g' $ZK_HOME/conf/log4j.properties
sed -i -r 's|#metricsProvider|metricsProvider|g'  $ZK_HOME/conf/zoo.cfg

export ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"

# since we are root, we can change the ownership of zookeeper files

current_uid=$(stat -c "%u" ${ZK_HOME}"/data")
current_gid=$(stat -c "%g" ${ZK_HOME}"/data")

if [ $current_uid != 1000 ] || [ $current_gid != 1000 ]; then
  echo "[Edge.One][*** MIGRATION START ***] Change ownership of zookeeper data files. This may take several minutes."
  chown -R 1000:1000 $ZK_HOME/data
  echo "[Edge.One][*** MIGRATION END ***] Change ownership of zookeeper files finished."
else
  echo "[Edge.One][INFO] Zookeeper data files are owned by $current_uid:$current_gid."
fi

current_uid=$(stat -c "%u" ${ZK_HOME}"/conf")
current_gid=$(stat -c "%g" ${ZK_HOME}"/conf")

if [ $current_uid != 1000 ] || [ $current_gid != 1000 ]; then
  echo "[Edge.One][*** MIGRATION START ***] Change ownership of zookeeper config files. This may take several minutes."
  chown -R 1000:1000 $ZK_HOME/conf
  echo "[Edge.One][*** MIGRATION END ***] Change ownership of zookeeper config files finished."
else
  echo "[Edge.One][INFO] Zookeeper data files are owned by $current_uid:$current_gid."
fi

/opt/zookeeper/bin/zkServer.sh start-foreground
