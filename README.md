# Установка Hadoop в Gentoo 
emerge sys-cluster/apache-hadoop-bin

### *this project is no longer supported*

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
**Preparation**
* (optional) Specify the cluster topology in `/etc/hosts` by adding the server(s) supported by each host in the comments. Also add the keyword `sandbox` to each line if you want a Sandbox deployment with minimal settings. 
Example:
~~~
192.168.56.11 hadoop1.mydomain.com hadoop1 # sandbox namenode datanode nodemanager resourcemanager
192.168.56.12 hadoop2.mydomain.com hadoop2 # sandbox secondarynamenode datanode nodemanager historyserver
~~~
If not done, installation will assume a single-node cluster 

**Installation**
~~~
emerge sys-cluster/apache-hadoop-bin
su - hdfs -c 'hdfs namenode -format'   # format the namenode
rc-service hadoop-namenode start       # start the namenode
rc-service hadoop-datanode start       # start the datanode
su - hdfs -c 'hadoop fs -mkdir -p /tmp/hadoop-yarn ; hadoop fs -chmod 777 /tmp/hadoop-yarn' # create TMP dir
rc-service hadoop-xxxx start            # start module xxx
~~~

This package will create the Unix users `hdfs:hadoop`, `yarn:hadoop` and `mapred:hadoop` (if they do not exist).

**Configuration**

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

**Verifications**
* Add your standard Unix user to group `hadoop`
* Log with this Unix user, create the home directory eg eg `hadoop fs -mkdir -p /user/guest`
* Add one sample file to HDFS eg `hadoop fs -put /usr/portage/distfiles/hadoop-2.7.1.tar.gz`
* Check NameNode status on http://<namenode>:50070/ especially the #blocks and the replication
* Check ResourceManager status on http://<resourcemanager>:8088/
* Check HistoryServer status on http://<historyserver>:19888/
* Remove the sample file  `hadoop fs -rm /usr/portage/distfiles/hadoop-2.7.1.tar.gz`
* Install Pig and run a MapReduce Job

### Apache Pig (0.15.0)
**Installation**
~~~
emerge dev-lang/apache-pig-bin
~~~
**Verifications**
* From your standard Unix user, download the tutorial file `https://cwiki.apache.org/confluence/download/attachments/27822259/pigtutorial.tar.gz`, extract from the archive the file `excite.log.bz2` and unzip it
* Add it to HDFS `hadoop fs -put excite.log` (with sandbox settings file is split in 4 blocks)
* Run Grunt shell `pig` then
~~~
a = LOAD 'excite.log' USING PigStorage('\t') AS (user, time, query:chararray);
b = FILTER a BY (query MATCHES '.*queen.*');
STORE b into 'verif_pig';
~~~
**Issues**
* `pig -x tez` not yet supported
* `pig -useHCatalog` : add to CLASSPATH datanucleus-*.jar and jdbc-mysql.jar

### Apache Hive (1.2.1)
**Installation**
* Install MySQL for the Hive Metastore database and create file /root/.my.cnf to allow direct connection from Unix user `root`
~~~
emerge dev-db/apache-hive-bin
~~~
This package will create the Unix user `hive:hadoop`
**Verifications**
* From your standard Unix user, run the command `hive` then enter following HQL lines
~~~
CREATE TABLE sample (userid STRING,time INT,query STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';
LOAD DATA INPATH 'excite.log' OVERWRITE INTO TABLE sample;
SELECT COUNT(*) FROM sample;
-- this will run a mapreduce job that should return 944954
DROP TABLE sample;
~~~

### Apache HBase (1.0.2)
~~~
emerge dev-db/apache-hbase-bin
~~~
**Verifications**
*in progress*

### Apache Sqoop (1.4.6)
~~~
emerge sys-cluster/apache-sqoop-bin
~~~
**Verifications**
* In MySQL, create a table `USE test; CREATE TABLE sample (userid varchar(100), time INT,query varchar(100));`
* then load data to it eg `LOAD DATA INFILE '/home/hadoop/excite.log' INTO TABLE sample FIELDS TERMINATED BY '\t';`
* Import table to HDFS: `/opt/sqoop/bin/sqoop import --connect jdbc:mysql://localhost/test --username root --pasword *** --table sample -m 1 `
* It should create a HDFS directory `sample`

### Spark (1.5.0, hadoop based version)
**Preparation**
* Specify the spark master in `/etc/hosts`. Optionally add the keyword `sandbox` for a deployment with minimal settings
* Example: `192.168.56.11 hadoop1.mydomain.com hadoop1 # sandbox sparkmaster`
**Installation**
~~~
emerge sys-cluster/apache-spark-bin
rc-service spark-master start
rc-service spark-worker start # to be done on each cluster node
~~~
This package will create the Unix user `spark:hadoop` and 
**Configuration**

Spark configuration can be found in `/etc/spark`

**Verifications**
* Check cluster status on http://<master>:7077/, you should see all workers there
* From your standard Unix user, create a sample text file and run the Word Count in `pyspark`:
~~~
sc.textFile("SAMPLE.txt").flatMap(lambda s: s.split(" ")).map(lambda s: (s, 1)).reduceByKey(lambda a, b: a + b).collect()
~~~
* Run a spark job (to be completed)


### Solr (5.3.1)
**Installation**
~~~
emerge dev-db/apache-solr-bin
rc-service solr start
rc-update add solr
~~~
**Verifications**
* Check status on http://<server>:8983/solr/


### Cassandra (2.2.1 latest)
Note: cassandra has no dependency with Hadoop Common packages and can be installed separately. 
**Preparation**

To install cassandra in cluster mode just add the keyword `cassandraseed` in `/etc/hosts` for the seed(s)
The keyword `sandbox`can be added too to reduce the memory settings to minimum
**Installation**
~~~
emerge dev-db/apache-cassandra-bin
rc-service cassandra start       # start the DB (to be done on all cluster nodes)
su - cassandra nodetool status   # cluster status
~~~
**Verifications**
* 


## To Do
* Add the ebuild to the gentoo overlay repository (https://wiki.gentoo.org/wiki/Project:Overlays)


