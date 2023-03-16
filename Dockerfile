FROM germanedge-docker.artifactory.new-solutions.com/edge-one/ge-ubuntu-generic:2.10.0

ARG zookeper_version=3.8.1

ENV ZOOKEEPER_VERSION=$zookeper_version
ENV PORT=2181
ENV SERVICENAME=zookeeper
ENV CONSUL_TAGS='"web","application","prometheus"'
ENV CONSUL_META_SCRAPE_PATH="\/metrics"
ENV CONSUL_META_SCRAPE_PORT="7071"
ENV FILEBEAT_ARGS='--E filebeat.inputs.2.paths=["/opt/zookeeper/logs/*.log"]'

USER root

RUN apt-get update \
  && apt-get install -y openjdk-17-jre-headless supervisor \
  && apt-get clean

#set permission for java certificates
RUN chown edgeone:edgeone /etc/default/cacerts
RUN chown edgeone:edgeone /etc/ssl/certs/java/cacerts

#Download Zookeeper
RUN curl https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz -o /tmp/zookeeper.tar.gz \
  && tar -xzf /tmp/zookeeper.tar.gz -C /opt \
  && mv /opt/apache-zookeeper-${ZOOKEEPER_VERSION}-bin /opt/zookeeper \
  && rm -rf /tmp/zookeeper.tar.gz

#Configure
RUN mv /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
ENV ZK_HOME /opt/zookeeper
RUN sed  -i "s|/tmp/zookeeper|$ZK_HOME/data|g" $ZK_HOME/conf/zoo.cfg; mkdir $ZK_HOME/data

RUN mkdir -p /opt/prometheus/ \
  && curl https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar -o /opt/prometheus/jmx-exporter.jar

COPY --chown=edgeone:root prometheus_zk.yml /opt/prometheus/

ENV SERVER_JVMFLAGS='-javaagent:/opt/prometheus/jmx-exporter.jar=7071:/opt/prometheus/prometheus_zk.yml'

RUN chown -R edgeone:edgeone /opt/zookeeper

WORKDIR /opt/zookeeper
VOLUME ["/opt/zookeeper/conf", "/opt/zookeeper/data"]

USER 1000

COPY --chown=edgeone:root startup.sh /app/startup.sh
COPY --chown=edgeone:root service.json /app/service.json

RUN chmod +x /app/startup.sh
