# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
inherit user java-utils-2

MY_PN="hadoop"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Software framework for data intensive distributed applications"
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="mirror://apache/hadoop/common/hadoop-${PV}/hadoop-${PV}.tar.gz"


LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror binchecks"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.6
	net-misc/openssh
	net-misc/rsync"

S=${WORKDIR}/hadoop-${PV}
INSTALL_DIR=/opt/hadoop
export CONFIG_PROTECT="${CONFIG_PROTECT} ${INSTALL_DIR}/etc/hadoop"

pkg_setup(){
	enewgroup hadoop
	enewuser hdfs -1 /bin/bash /home/hdfs hadoop
	enewuser yarn -1 /bin/bash /home/yarn hadoop
	enewuser mapred -1 /bin/bash /home/mapred hadoop
	chgrp hadoop /home/yarn /home/mapred /home/hdfs
}

src_install() {
	# get the topology from /etc/hosts
	hostname=`uname -n`
	namenode=`egrep "^[0-9].*#.* namenode" /etc/hosts | awk '{print $2}' `
	[[ -n $namenode ]] || namenode=$hostname
	secondarynamenode=`egrep "^[0-9].*#.* secondarynamenode" /etc/hosts | awk '{print $2}'`
	[[ -n $secondarynamenode ]] || secondarynamenode=$hostname
	resourcemanager=`egrep "^[0-9].*#.* resourcemanager" /etc/hosts | awk '{print $2}'`
	[[ -n $resourcemanager ]] || resourcemanager=$hostname
	historyserver=`egrep "^[0-9].*#.* historyserver" /etc/hosts | awk '{print $2}'`
	[[ -n $historyserver ]] || historyserver=$hostname

	replication=`egrep -c "^[0-9].*#.* datanode" /etc/hosts`
	[ $replication -ge 3 ] && replication=0
	sandbox=`egrep -c "^[0-9].*#.* sandbox" /etc/hosts`

	# The hadoop-env.sh file needs JAVA_HOME set explicitly
	JAVA_HOME=$(java-config -g JAVA_HOME)
	sed -e "1iexport JAVA_HOME=${JAVA_HOME}" -i etc/hadoop/hadoop-env.sh || die "sed failed"
	# Also set the Log and PID dir
	sed -e "2iexport HADOOP_PID_DIR=/var/tmp/hadoop" -i etc/hadoop/hadoop-env.sh
	sed -e "3iexport HADOOP_LOG_DIR=/var/log/hadoop" -i etc/hadoop/hadoop-env.sh
	[ $sandbox -ne 0 ] && sed -e "4iexport HADOOP_HEAPSIZE=200" -i etc/hadoop/hadoop-env.sh

	# yarn-env.sh
	sed -e "1iexport JAVA_HOME=${JAVA_HOME}" -i etc/hadoop/yarn-env.sh || die "sed failed"
	sed -e "2iexport YARN_CONF_DIR=/etc/hadoop" -i etc/hadoop/yarn-env.sh
	sed -e "3iexport YARN_LOG_DIR=/var/log/hadoop" -i etc/hadoop/yarn-env.sh
	[ $sandbox -ne 0 ] && sed -e "4iexport YARN_HEAPSIZE=200" -i etc/hadoop/yarn-env.sh

	# mapred-env.sh
	sed -e "1iexport JAVA_HOME=${JAVA_HOME}" -i etc/hadoop/mapred-env.sh || die "sed failed"
	sed -e "2iexport HADOOP_MAPRED_LOG_DIR=/var/log/hadoop" -i etc/hadoop/mapred-env.sh
	[ $sandbox -ne 0 ] && sed -e "22iexport HADOOP_JOB_HISTORYSERVER_HEAPSIZE=100" -i etc/hadoop/mapred-env.sh

	# Update core-site.xml
	sed -e "20i<property><name>fs.defaultFS</name><value>hdfs://$namenode</value></property>" -i etc/hadoop/core-site.xml || die "sed failed"
	# Update hdfs-site.xml
	sed -e "21i<property><name>dfs.namenode.name.dir</name><value>file:/data/hdfs/name</value></property>" -i etc/hadoop/hdfs-site.xml
	sed -e "22i<property><name>dfs.datanode.data.dir</name><value>file:/data/hdfs/data</value></property>" -i etc/hadoop/hdfs-site.xml
	sed -e "23i<property><name>dfs.namenode.secondary.http-address</name><value>hdfs://${secondarynamenode}:50090</value></property>" -i etc/hadoop/hdfs-site.xml
	[ $replication -ne 0 ]  && sed -e "24i<property><name>dfs.replication</name><value>$replication</value></property>" -i etc/hadoop/hdfs-site.xml
	[ $sandbox -ne 0 ] && sed -e "24i<property><name>dfs.blocksize</name><value>10M</value></property>" -i etc/hadoop/hdfs-site.xml

	# Update yarn-site.xml
	sed -e "18i<property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>" -i etc/hadoop/yarn-site.xml || die "sed failed"
	sed -e "19i<property><name>yarn.resourcemanager.hostname</name><value>$resourcemanager</value></property>" -i etc/hadoop/yarn-site.xml
	if [ $sandbox -ne 0 ] ; then
	   sed -e "20i<property><name>yarn.scheduler.minimum-allocation-mb</name><value>100</value></property>" -i etc/hadoop/yarn-site.xml
	   sed -e "20i<property><name>yarn.scheduler.maximum-allocation-mb</name><value>100</value></property>" -i etc/hadoop/yarn-site.xml
	   sed -e "20i<property><name>yarn.nodemanager.resource.memory-mb</name><value>200</value></property>" -i etc/hadoop/yarn-site.xml
           sed -e "20i<property><name>yarn.scheduler.maximum-allocation-vcores</name><value>1</value></property>" -i etc/hadoop/yarn-site.xml
	fi

	# Update mapred-site.xml
	[ -f etc/hadoop/mapred-site.xml ] || cp etc/hadoop/mapred-site.xml.template etc/hadoop/mapred-site.xml
	sed -e "20i<property><name>mapreduce.framework.name</name><value>yarn</value></property>" -i etc/hadoop/mapred-site.xml || die "sed failed"
	sed -e "21i<property><name>mapreduce.jobhistory.address</name><value>$historyserver:10020</value></property>" -i etc/hadoop/mapred-site.xml
	if [ $sandbox -ne 0 ] ; then
	   sed -e "20i<property><name>mapreduce.map.memory.mb</name><value>100</value></property>" -i etc/hadoop/mapred-site.xml
	   sed -e "20i<property><name>mapreduce.reduce.memory.mb</name><value>100</value></property>" -i etc/hadoop/mapred-site.xml
	   sed -e "20i<property><name>yarn.app.mapreduce.am.resource.mb</name><value>100</value></property>" -i etc/hadoop/mapred-site.xml
	fi

	# make useful dirs
	diropts -m770 -o root -g hadoop
	dodir /var/log/"${MY_PN}"
	dodir /var/tmp/"${MY_PN}"
	dodir /data/hdfs

	# install dir
	dodir "${INSTALL_DIR}"
	mv "${S}"/* "${D}${INSTALL_DIR}" || die "install failed"
	chown -Rf root:hadoop "${D}${INSTALL_DIR}"

	# env file
	cat > 99hadoop <<-EOF
		HADOOP_HOME="${INSTALL_DIR}"
		HADOOP_YARN_HOME="${INSTALL_DIR}"
		HADOOP_MAPRED_HOME="${INSTALL_DIR}"
		PATH="${INSTALL_DIR}/bin"
		CONFIG_PROTECT="${INSTALL_DIR}/etc/hadoop"
	EOF
	doenvd 99hadoop || die "doenvd failed"

	# conf symlink
	dosym ${INSTALL_DIR}/etc/hadoop /etc/hadoop

	# init scripts
	newinitd "${FILESDIR}"/"${MY_PN}".initd "${MY_PN}.initd"
	for i in "namenode" "datanode" "secondarynamenode" "resourcemanager" "nodemanager" "historyserver"
    	do if [ `egrep -c "^[0-9].*#.*namenode" /etc/hosts` -eq 0 ] || [ `egrep -c "^[0-9].*${hostname}.*#.* ${i}" /etc/hosts` -eq 1 ] ; then
	   dosym  /etc/init.d/"${MY_PN}.initd" /etc/init.d/"${MY_PN}"-"${i}"
	   fi
	done
}

pkg_postinst() {
	elog "For info on configuration see http://hadoop.apache.org/core/docs/r${PV}"
}
