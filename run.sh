#!/bin/bash

set -m

if [ "${INFLUXDB_ROOT_PASSWORD}" == "**ChangeMe**" ]; then
    echo "=> No password is specified for InfluxDB root user!"
    echo "=> Program terminated!"
    exit 1
fi

echo "=> Starting InfluxDB ..."
exec /usr/bin/influxdb -config=/config/config.toml &

#wait for the startup of influxdb
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of InfluxDB service startup ..."
    sleep 3 
    curl http://localhost:8086/ping 2> /dev/null
    RET=$?
done
echo ""


# check if default root password "root" is still valid
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=root")
if test $STATUS -eq 200; then
    # let's update the root password
    STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins/root?u=root&p=root" -d "{\"password\": \"${INFLUXDB_ROOT_PASSWORD}\"}")
    if test $STATUS -eq 200; then
        echo "=> InfluxDB root password successfully updated."
    else
        echo "=> Failed to update InfluxDB root password!"
        echo "=> Program terminated!"
        exit 1
    fi
else
    # default root password "root" has already been changed
    # check if the given one is valid:
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=${INFLUXDB_ROOT_PASSWORD}")
    if test $STATUS -eq 200; then
        echo "=> Password supplied for InfluxDB root user is already ok." 
    else
        echo "=> Password supplied for InfluxDB root user is wrong!"
        echo "=> Program terminated!"
        exit 1
    fi
fi

fg

