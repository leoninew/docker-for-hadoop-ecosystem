#!/bin/bash

/usr/sbin/sshd

# postgresql-setup initdb # error
su - postgres -c "initdb"
# cat /var/lib/pgsql/data/postgresql.conf | grep address
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
echo "host all all 0.0.0.0/0 md5" >> /var/lib/pgsql/data/pg_hba.conf
su - postgres -c "postgres -D /var/lib/pgsql/data &"

HADOOP_HOME="/opt/hadoop"
$HADOOP_HOME/bin/hadoop namenode -format
$HADOOP_HOME/bin/hadoop fs -chown -R root:root /tmp
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

psql -U postgres -c "Create database metastore with owner=postgres"
psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'postgres'"

$HADOOP_HOME/bin/hadoop fs -mkdir -p /hive/warehouse 
$HADOOP_HOME/bin/hadoop fs -chmod g+w /hive/warehouse

HIVE_HOME="/opt/hive"
$HIVE_HOME/bin/schematool -dbType postgres -initSchema
nohup $HIVE_HOME/bin/hive --service metastore &
nohup $HIVE_HOME/bin/hive --service hiveserver2 &
# nohup $HIVE_HOME/bin/hive –-service hwi &


if [ $# == 0 ];then
    bash
else
    exec $@
fi