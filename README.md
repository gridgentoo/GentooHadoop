# Gentoo Hadoop
An up-to-date deployment process for Hadoop ecosystem on Gentoo Linux. The ebuilds were collected from different repositories and updated to align with the latest software versions and the deployments modes described below

## Motivation

The objective of this projet is to ease the installation and deployment of Hadoop on Gentoo Linux. It supports 2 deployment modes
 1. Standard 
 2. Sandbox in single or multi-node cluster with minimal resource consumption (ability to run on small VMs with 1 core/2GB each)

## Installation
### Prequisites
* Hadoop data file systems will be stored by default under `/data` directory. It is recommended to mount a dedicated partition on `/data` or at least to create the directory if it does not exists 
* OPTIONAL. Specify the cluster topology in `/etc/hosts` by adding the module(s) supported by each server in comments. Also add the keyword `sandbox` to the namenode if you want a Sandbox deployment with minimal settings

Example:
~~~
192.168.56.11 hadoop1.mydomain.com hadoop1 # sandbox namenode datanode nodemanager resourcemanager
192.168.56.12 hadoop2.mydomain.com hadoop2 # secondarynamenode datanode nodemanager historyserver
~~~

* Copy manually the portage overlay directories to `/usr/local/portage/`
* Digest the ebuilds, example:
~~~
cd /usr/local/portage/sys-cluster/apache-hadoop-bin
ebuild apache-hadoop-bin-2.7.1.ebuild digest
~~~
* Add to `/etc/portage/package.accept_keywords` upon request

(this is a temporary solution until use of Gentoo overlay)

### Apache Hadoop Common (2.7.1)
~~~
emerge sys-cluster/apache-hadoop-bin
su - hdfs -c 'hdfs namenode -format '  # format the namenode

/etc/init.d/hadoop-namenode start      # start the namenode
rc-update add hadoop-namenode          # add the namenode to boot
/etc/init.d/hadoop-xxx start           # start module xxx 
rc-update add hadoop-xxx               # add the module xxx to boot

su - hdfs -c 'hadoop fs -mkdir /tmp ; hadoop fs -chmod 777 /tmp' # create the HDFS tmp dir

~~~
Ignore the emerge warnings `QA Notice..` on the Elf files

This package will create the Unix users `hdfs`, `yarn` and `mapred` if they do not exist. Set the passwords for those users

Verifications:
* Login as `mapred` and add file to HDFS for instance `hadoop fs -put  /usr/portage/distfiles/hadoop-2.7.1.tar.gz  /`
* Check NameNode status on http://<namenode>:50070/
* Check ResourceManager status on http://<resourcemanager>:8088/
* Check HistoryServer status on http://<historyserver>:19888/
* Install Pig and run a MapReduce Job

### Apache Pig (0.15.0)
~~~
emerge dev-lang/apache-pig-bin
~~~
Verifications:
* Login as `mapred` (any Unix user can be used for Pig), download and extract the tutorial file `https://cwiki.apache.org/confluence/download/attachments/27822259/pigtutorial.tar.gz`
* From the extracted dir, run `hadoop fs -copyFromLocal excite.log.bz2 .` (in case of failure create the HDFS dir `/user/mapred` with proper rights)
* Run Pig in local mode: `pig -x local script1-local.pig` 
* Run Pig in mapreduce mode: `pig script1-hadoop.pig`

### Apache Hive (1.2.1)
~~~
emerge dev-db/apache-hive-bin
su - hdfs -c 'hadoop fs -mkdir /tmp/hive /user/hive/warehouse'
su - hdfs -c 'hadoop fs -chmod 733 /tmp/hive /user/hive/warehouse'
~~~
Verifications:
* Login as `hive`, unzip the above file excite.log.bz2 and copy it to HDFS (` hadoop fs -copyFromLocal excite.log`)
* Run the Unix command `/opt/hive/bin/hive` then enter following HQL lines
~~~
CREATE DATABASE test;
USE test;
CREATE TABLE sample (userid STRING, time INT, query STRING)  ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
LOAD DATA INPATH 'excite.log' OVERWRITE INTO TABLE sample;
SELECT COUNT(*) FROM sample;
-- this will run a mapreduce job that should return 944954
DROP TABLE sample;
DROP DATABASE test;
~~~

### Apache HBase (1.0.2)
~~~
emerge dev-db/apache-hbase-bin
~~~
Verifications:
*in progress*

### Apache Sqoop (1.4.6)
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
/etc/init.d/spark-master start
/etc/init.d/spark-worker start # to be done on each cluster node

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
/etc/init.d/solr start
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
/etc/init.d/cassandra start      # start the DB (to be done on all cluster nodes)
rc-update add cassandra          # add to boot
su - cassandra nodetool status   # cluster status
~~~



## Environment Details
* Users created
~~~
hdfs:hadoop
yarn:hadoop
mapred:hadoop
hive:hadoop
spark:hadoop
solr:hadoop
cassandra:cassandra
~~~
* Directories created
~~~
/opt/hadoop       # Hadoop binaries
/etc/hadoop       # Hadoop config files (including Pig, Spark)
/var/log/hadoop   # Hadoop log files
/data/hdfs        # HDFS data files

/opt/pig          # Pig binaries

/opt/hive         # Hive binaries

/opt/spark        # Spark binaries
/etc/spark        # Spark config files
/data/spark       # Spark working file
/var/log/spark    # Spark logs

/opt/cassandra    # Cassandra binaries
/data/cassandra   # Cassandra DB files
/var/log/cassandra # Cassandra log files

~~~
* Environment files

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


