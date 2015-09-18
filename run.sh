#!/bin/bash

set -m


abort() {
    echo "=> Environment was:"
    env
    echo "=> Program terminated!"
    exit 1
}

check_update_root_password() {
    # check if default root password "root" is still valid
    status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=root")
    if test $status -eq 200; then
        # let's update the root password
        status=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins/root?u=root&p=root" -d "{\"password\": \"${ROOT_PASSWORD}\"}")
        if test $status -eq 200; then
            echo "=> InfluxDB root password successfully updated."
        else
            echo "=> Failed to update InfluxDB root password!"
            abort
        fi
    else
        # default root password "root" has already been changed
        # check if the given one is valid:
        status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8086/cluster_admins?u=root&p=${ROOT_PASSWORD}")
        if test $status -eq 200; then
            echo "=> Password supplied for InfluxDB root user is already ok."
        else
            echo "=> Password supplied for InfluxDB root user is wrong!"
            abort
        fi
    fi
}

create_db() {
    db=$1
    /opt/influxdb/influx -database ${db} -execute 'show measurements' > /dev/null
    if [ $? -eq 0 ]; then
        echo "=> Database \"${db}\" already exists."
    else
        echo "=> Creating database: ${db}"
        /opt/influxdb/influx -execute "create database ${db}"
        if [ $? -eq 0]; then
            echo "=> Database \"${db}\" successfully created."
        else
            echo "=> Failed to create database \"${db}\"!"
            abort
        fi
    fi
}

create_dbuser() {
    db=$1
    user=$2
    password=$3
    admin=${4:-"false"}
    admin=${admin,,} # convert to lowercase
    if [ -z "${db}" ] || [ -z "${user}" ] || [ -z "${password}" ] ; then
        echo "=> create_dbuser first 3 args are required (db, user, and password)."
        abort
    fi
    if [ "${admin}" != "true" ] && [ "${admin}" != "false" ]; then
        echo "=> Wrong value for create_dbuser admin arg: ${admin}"
        echo "   Value should be either \"true\" or \"false\"."
        abort
    fi
    /opt/influxdb/influx -execute "create user ${user} with password '${password}'"
    if [ $? -ne 0 ]; then
        echo "=> Db user \"${db}/${user}\" already exists: trying to update the password."
        # let's update the user password
        /opt/influxdb/influx -execute "set password for ${username} = '${password}'"
        if [ $? -eq 0]; then
            echo "=> Password for db user \"${db}/${user}\" successfully updated."
        else
            echo "=> Failed to update password for \"${db}/${user}\" db user!"
            abort
        fi
    fi

    # update admin rights
    if [ "${admin}" == "true" ]; then
        data="{\"admin\":true,\"name\":\"${user}\",\"readFrom\":\".*\",\"writeTo\":\".*\"}"
    else
        data="{\"admin\":false,\"name\":\"${user}\",\"readFrom\":\".*\",\"writeTo\":\"^$\"}"
    fi
    status=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://localhost:8086/db/${db}/users/${user}?u=root&p=${ROOT_PASSWORD}" -d "${data}")
    if test $status -eq 200; then
        echo "=> Admin rights successfully updated for db user \"${db}/${user}\"."
    else
        echo "=> Failed to update admin rights for db user: \"${db}/${user}\""
    fi
}

######### MAIN #########

if [ "${ROOT_PASSWORD}" == "**ChangeMe**" ]; then
    echo "=> No password is specified for InfluxDB root user!"
    abort
fi

CONFIG_FILE="/etc/opt/influxdb/influxdb.conf"
MAX_OPEN_FILES=${MAX_OPEN_FILES:-32768}

# Dynamically change both ulimit value and the 'max-open-shards' value in
# influxdb config
ulimit -n ${MAX_OPEN_FILES}

echo "=> Starting InfluxDB ..."
exec /opt/influxdb/influxd -config=${CONFIG_FILE} &

# Wait for InfluxDB to start
ret=1
while [[ ret -ne 0 ]]; do
    echo "=> Waiting for confirmation of InfluxDB service startup ..."
    sleep 3
    curl -s -o /dev/null http://localhost:8086/ping
    ret=$?
done
echo ""

#check_update_root_password

#if [ -z "${PRE_CREATE_DB}" ]; then
#    echo "=> No database names supplied: no database will be created."
#else
#    for db in $(echo ${PRE_CREATE_DB} | tr ";" "\n"); do
#        create_db $db
#        dbusers_var="PRE_CREATE_DBUSER_${db}"
#        if [ -z "${!dbusers_var}" ]; then
#            echo "=> No dbusers supplied for database ${db}: no user will be created."
#        else
#            for user in $(echo ${!dbusers_var} | tr ";" "\n"); do
#                dbuserpassword_var="${db}_${user}_PASSWORD"
#                dbuseradmin_var="${db}_${user}_ADMIN"
#                create_dbuser $db $user ${!dbuserpassword_var} ${!dbuseradmin_var}
#            done
#        fi
#    done
#fi

fg

