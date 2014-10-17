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

- `INFLUXDB_DEFAULT_DB_NAME`: the name of the default database to create
  (only set this env variable if you actually want a default database to be
  automatically created).
- `INFLUXDB_DEFAULT_DB_USER`: the name of the admin user to create for the
  above default database (only set this env variable if you actually want a
  database admin user to be automatically created).
- `INFLUXDB_DEFAULT_DB_PASSWORD`: the password of the admin user to create
  for the above default database.

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
