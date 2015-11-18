# Gentoo Hadoop
An up-to-date deployment process for Hadoop ecosystem on Gentoo Linux. The ebuilds were collected from different repositories and updated to align with the latest software versions and the deployments modes described below

## Motivation

The objective of this projet is to ease the installation and deployment of Hadoop components on Gentoo Linux. It supports 2 deployment modes
 1. Standard 
 2. Sandbox in a single or multi-node cluster with minimal resource consumption (ability to run on small VMs with 1 core/2GB each)

## Installation Prequisites
* Copy manually the portage overlay directories to `/usr/local/portage/` for instance
* Update `/etc/portage/package.accept_keywords` with the included file
* Digest the ebuilds
~~~
find /usr/local/portage/ -name *.ebuild -exec ebuild {} digest \;
~~~
(this is a temporary solution until use of Gentoo overlay)

## Installation Rules
* A Unix user is created for each type of servers especially `hdfs`, `yarn`, etc.
* The binaries are installed in /opt/<component>-<version>/
* The configuration files are setup /etc/<component>/
* The log files can be found in /var/log/<component>/
* The PID files are stored in /var/run/pids/
* The data files are stored in /var/lib

## Components

### Apache Hadoop Common (2.7.1)
*Preparation*
* (optional) Specify the cluster topology in `/etc/hosts` by adding the server(s) supported by each host in the comments. Also add the keyword `sandbox` to each line if you want a Sandbox deployment with minimal settings. 
Example:
~~~
192.168.56.11 hadoop1.mydomain.com hadoop1 # sandbox namenode datanode nodemanager resourcemanager
192.168.56.12 hadoop2.mydomain.com hadoop2 # sandbox secondarynamenode datanode nodemanager historyserver
~~~
If not done, installation will assume a single-node cluster 

*Installation*
~~~
emerge sys-cluster/apache-hadoop-bin
su - hdfs -c 'hdfs namenode -format'   # format the namenode
rc-service hadoop-namenode start       # start the namenode
rc-service hadoop-datanode start       # start the datanode
su - hdfs -c 'hadoop fs -mkdir -p /tmp/hadoop-yarn ; hadoop fs -chmod 777 /tmp/hadoop-yarn' # create TMP dir
rc-service hadoop-xxxx start            # start module xxx
~~~

This package will create the Unix users `hdfs:hadoop`, `yarn:hadoop` and `mapred:hadoop` (if they do not exist).

*Configuration*
Basically everything is configured automatically. The environment files `hadoop-env.sh`, `yarn-env.sh` and `mapred-env.sh` are updated with proper `$JAVA_HOME` and a minimal JAVA Heap size in case of sandbox
The properties files are updated as below
~~~
core-site.xml
  fs.defaultFS          # hdfs://<hostname of "namenode">
hdfs-site.xml
  dfs.namenode.name.dir # file:/var/lib/hdfs/name
  dfs.datanode.data.dir # file:/var/lib/hdfs/data
  dfs.namenode.secondary.http-address # <hostname of "secondarynode">:50090
  dfs.replication       # number of data nodes if <3 otherwise 3
  dfs.blocksize         # 10M if sandbox otherwise default
  dfs.permissions.superusergroup # set to 'hadoop'
yarn-site.xml
  yarn.nodemanager.aux-services # mapreduce_shuffle
  yarn.resourcemanager.hostname # hostname of "resourcemanager"
  yarn.nodemanager.resource.memory-mb  # set to minimal value if sandbox
  yarn.nodemanager.resource.cpu-vcores # set to 1 if sandbox
  yarn.scheduler.maximum-allocation-mb # set to memory-mb/3 if sandbox
  yarn.nodemanager.vmem-pmem-ratio     # set to 1 if sandbox
mapred-site.xml
  mapreduce.framework.name          # yarn
  mapreduce.jobhistory.addresss     # <hostname of "historyserver">:10020
  yarn.app.mapreduce.am.resource.mb # set to minimal value if sandbox
  mapreduce.map.memory.mb           # set to minimal value if sandbox
  mapreduce.reduce.memory.mb        # set to minimal value if sandbox
~~~

*Verifications*
* Add your standard Unix user to group `hadoop`
* Log with this Unix user, create the home directory eg eg `hadoop fs -mkdir -p /user/guest`
* Add one file to HDFS eg `hadoop fs -put /usr/portage/distfiles/hadoop-2.7.1.tar.gz`
* Check NameNode status on http://<namenode>:50070/ especially the #blocks and the replication
* Check ResourceManager status on http://<resourcemanager>:8088/
* Check HistoryServer status on http://<historyserver>:19888/
* Renove the file  `hadoop fs -rm /usr/portage/distfiles/hadoop-2.7.1.tar.gz`
* Install Pig and run a MapReduce Job

### Apache Pig (0.15.0)
*Installation*
~~~
emerge dev-lang/apache-pig-bin
~~~
*Verifications*
* From your standard Unix user, download the tutorial file `https://cwiki.apache.org/confluence/download/attachments/27822259/pigtutorial.tar.gz`, extract from the archive the file `excite.log.bz2` and unzip it
* Add it to HDFS `hadoop fs -put excite.log` (with sandbox settings file is spit in 4 blocks)
* Run Grunt shell `epig` then
~~~
a = LOAD 'excite.log' USING PigStorage('\t') AS (user, time, query:chararray);
b = FILTER a BY (query MATCHES '.*queen.*');
STORE b into 'verif_pig';
~~~


Pig in local mode: `pig -x local script1-local.pig` 
* Run Pig in mapreduce mode: `pig script1-hadoop.pig`


### Apache Hive (1.2.1)
* Install MySQL for the Hive Metastore database and create file /root/.my.cnf to allow direct connection from Unix user `root`
~~~
emerge dev-db/apache-hive-bin
su - hdfs -c 'hadoop fs -mkdir /tmp/hive /user/hive/warehouse'
su - hdfs -c 'hadoop fs -chmod 733 /tmp/hive /user/hive/warehouse'
~~~
Verifications:
* Login as `hive`, unzip the above file excite.log.bz2 and copy it to HDFS (`hadoop fs -copyFromLocal excite.log`)
* Run the Unix command `/opt/hive/bin/hive` then enter following HQL lines
~~~
CREATE TABLE sample (userid STRING, time INT, query STRING)  ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';
LOAD DATA INPATH 'excite.log' OVERWRITE INTO TABLE sample;
SELECT COUNT(*) FROM sample;
-- this will run a mapreduce job that should return 944954
DROP TABLE sample;
~~~

### Apache HBase (1.0.2)
~~~
emerge dev-db/apache-hbase-bin
~~~
Verifications:
*in progress*

### Apache Sqoop (1.99.6)
~~~
emerge sys-cluster/apache-sqoop-bin
~~~
Verifications:
*in progress*

### Apache Flume (1.6.0)
~~~
emerge sys-cluster/apache-flume-bin
~~~
Verifications:
*in progress*

### Spark (1.5.0, hadoop based version)
~~~
emerge sys-cluster/apache-spark-bin
rc-service spark-master start
rc-service spark-worker start # to be done on each cluster node

~~~
Verifications:
* Check cluster status on http://<master>:7077/, you should see all workers there
* Login as `spark` and copy a text file for instance `README.md`
* Run the following commands in PythonSpark (`pyspark`) and check results
~~~
textFile = sc.textFile("README.md")
textFile.count()
~~~
* Run a spark job (to be completed)


### Solr (5.3.1)
~~~
emerge dev-db/apache-solr-bin
rc-service solr start
rc-update add solr
~~~
Verifications:
* Check status on http://<server>:8983/solr/


### Cassandra (2.2.1 latest)
Note: cassandra has no dependency with Hadoop Common packages and can be installed separately. 

To install cassandra in cluster mode just add the keyword `seed` in `/etc/hosts` for the seed(s)
The sandbox option will reduce the memory settings to minimum (256MB)
~~~
emerge dev-db/apache-cassandra-bin
rc-service cassandra start      # start the DB (to be done on all cluster nodes)
rc-update add cassandra          # add to boot
su - cassandra nodetool status   # cluster status
~~~



## Environment Details

Environment files

The configuration files `hadoop-env.sh`, `yarn-env.sh` and `mapred-env.sh` are updated with local `$JAVA_HOME` and a minimal JAVA Heap size in case of sandbox
* Hadoop properties
~~~
core-site.xml
  fs.defaultFS          # hdfs://<hostname of "namenode">
hdfs-site.xml
  dfs.namenode.name.dir # file:/data/hdfs/name
  dfs.datanode.data.dir # file:/data/hdfs/data
  dfs.namenode.secondary.http-address # <hostname of "secondarynode">:50090
  dfs.replication       # number of data nodes if <3 otherwise use default
  dfs.blocksize         # 10M if sandbox otherwise use default
yarn-site.xml
  yarn.nodemanager.aux-services # mapreduce_shuffle
  yarn.resourcemanager.hostname # hostname of "resourcemanager"
  yarn.scheduler.minimum-allocation-mb # set to 100M for sandbox 
  yarn.scheduler.maximum-allocation-mb # set to 100M for sandbox
  yarn.nodemanager.resource.memory-mb  # set to 200M for sandbox 
mapred-site.xml
  mapreduce.framework.name      # yarn
  mapreduce.jobhistory.addresss # <hostname of "historyserver">:10020
  mapreduce.map.memory.mb       # set to 100M for sandbox 
  mapreduce.reduce.memory.mb    # set to 100M for sandbox 
  yarn.app.mapreduce.am.resource.mb   # set to 100M for sandbox
~~~

## To Do
* Review the ebuilds code to align with best practices
* handle the product versions in installations directories
* Add the ebuild to the gentoo overlay repository (https://wiki.gentoo.org/wiki/Project:Overlays)


