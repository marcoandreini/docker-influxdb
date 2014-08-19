FROM debian:wheezy
MAINTAINER Bruno Binet <bruno.binet@gmail.com>
 
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl ca-certificates
ENV INFLUXDB_VERSION 0.8.0-rc.5

# Install InfluxDB
RUN curl -s -o /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb http://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  dpkg -i /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm /tmp/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
  rm -rf /var/lib/apt/lists/*

ADD config.toml /config/config.toml
ADD run.sh /run.sh
RUN chmod +x /*.sh

ENV INFLUXDB_DEFAULT_DB_NAME **None**
ENV INFLUXDB_DEFAULT_DB_USER **None**
ENV INFLUXDB_DEFAULT_DB_PASSWORD **None**
ENV INFLUXDB_ROOT_PASSWORD **ChangeMe**

# Admin server
EXPOSE 8083

# HTTP API
EXPOSE 8086

# HTTPS API
EXPOSE 8084

# Raft port (for clustering, don't expose publicly!)
#EXPOSE 8090

# Protobuf port (for clustering, don't expose publicly!)
#EXPOSE 8099

VOLUME ["/data"]

CMD ["/run.sh"]
