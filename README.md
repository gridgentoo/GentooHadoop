# Gentoo Hadoop
An up-to-date deployment process for Hadoop modules on Gentoo Linux

## Motivation

The objective of this projet is to ease the installation and deployment of Hadoop modules on Gentoo Linux. It supports 2 deployment modes
 1. Standard 
 2. Sandbox in single or multi-node cluster with minimal resource consumption (ability to run on small VMs with 1 core/2GB each)

## Installation
### Prequisites
* Hadoop data file systems will be stored by default under `/data` directory. It is recommended to mount a dedicated partition on `/data` or at least to create the directory if it does not exists
* OPTIONAL. Specify the cluster topology in `/etc/hosts` by adding the module(s) supported by each server in comments. Also add the keyword `sandbox` for the namenode if you want a Sandbox deployment with minimal settings

Example:
~~~
192.168.56.11 hadoop1.mydomain.com hadoop1 # sandbox namenode datanode nodemanager resourcemanager
192.168.56.12 hadoop2.mydomain.com hadoop2 # secondarynamenode datanode nodemanager historyserver
~~~

* Copy manually the portage overlay directories to `/usr/local/portage/` for instance 
* Digest the ebuilds, example:
~~~
cd /usr/local/portage/sys-cluster/apache-hadoop-bin
ebuild apache-hadoop-bin-2.7.1.ebuild digest
~~~
* Add to `/etc/portage/package.accept_keywords` upon request

(temporary solution until use of Gentoo overlay)

### Hadoop Common (2.7.1)
~~~
emerge apache-hadoop-bin
su - hdfs -c 'hdfs namenode -format '  # format the namenode

/etc/init.d/hadoop-namenode start  # start the namenode
/etc/init.d/hadoop-datanode start  # start datanode
/etc/init.d/hadoop-xxx start       # start xxx (add to bootvia rc-update)

~~~
Ignore the warnings `QA Notice..` on the Elf files

This package will create the Unix users `hdfs`, `yarn` and `mapred` if they do not exist. Set the passwords for those users

### Pig (0.15.0)
~~~
emerge apache-pig-bin

~~~
### Spark (1.5.0 hadoop based)


## Environment Details
* Users created
~~~
hdfs:hadoop
yarn:hadoop
mapred:hadoop
~~~
* Directories created
~~~
/etc/hadoop       # config files
/var/log/hadoop/  # log files
/var/tmp/hadoop/  # tmp files including Process PIDs
/opt/hadoop       # binaries
/data/hdfs        # HDFS data files
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

* Add the ebuild to the gentoo overlay repository (https://wiki.gentoo.org/wiki/Project:Overlays)



