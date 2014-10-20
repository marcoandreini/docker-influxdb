docker-influxdb
===============

InfluxDB docker container.


Build
-----

To create the image `bbinet/influxdb`, execute the following command in the
`docker-influxdb` folder:

    docker build -t bbinet/influxdb .

You can now push the new image to the public registry:
    
    docker push bbinet/influxdb


Configure and run
-----------------

You can configure the InfluxDB running container with some environment
variables, see below.

Required:

- `ROOT_PASSWORD`: the password that must be set for the root
  admin user.

Optional:

- `PRE_CREATE_DB`: the list of the databases to create automatically at startup
  (example: `PRE_CREATE_DB="db1;db2;db3"`)
- `PRE_CREATE_DBUSER_<database>`: the list of the database users to create
  automatically at startup (example: `PRE_CREATE_DBUSER_db1="user1;user2"`)
- `<database>_<dbuser>_PASSWORD`: the password of the dbuser to create
  for the above database (example: `db1_user1_PASSWORD="mypass"`)
- `<database>_<dbuser>_ADMIN`: set if the dbuser to create should be granted
  admin rights for the above database (example: `db1_user1_ADMIN=ok`)

Then when starting your InfluxDB container, you will want to bind ports `8083`
and `8086` from the InfluxDB container to the host external ports.
InfluxDB container will write its `db`, `raft`, and `wal` data dirs to a data
volume in `/data`, so you may want to bind this data volume to a host
directory.

For example:

    $ docker pull bbinet/influxdb

    $ docker run --name influxdb \
          -v /home/influxdb/data:/data \
          -p 8083:8083 -p 8086:8086 \
          -e ROOT_PASSWORD=root_password \
          -e INFLUXDB_DEFAULT_DB_NAME=metrics \
          -e INFLUXDB_DEFAULT_DB_USER=admin \
          -e INFLUXDB_DEFAULT_DB_PASSWORD=admin_password \
          bbinet/influxdb

Optionally, you may want to also expose ports `8090` and `8099` to your host
since these are used for clustering, but they should not be exposed to the
internet. So you will add `--expose 8090 --expose 8099` to the above example.
