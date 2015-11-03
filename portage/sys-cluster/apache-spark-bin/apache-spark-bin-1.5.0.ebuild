# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit user java-utils-2

MY_PN="spark"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Software framework for fast cluster computing"
HOMEPAGE="http://spark.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${MY_P}/${MY_P}-bin-hadoop2.6.tgz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="scala"

DEPEND="scala? ( dev-lang/scala )"

RDEPEND=">=virtual/jre-1.6
	dev-java/maven-bin
	sys-cluster/apache-hadoop-bin
	scala? ( dev-lang/scala )"


S="${WORKDIR}/${MY_P}-bin-hadoop2.6"
INSTALL_DIR=/opt/spark

pkg_setup(){
	enewgroup hadoop
	enewuser spark -1 /bin/bash /home/spark hadoop
	chgrp hadoop /home/spark
}

src_install() {
	# create file spark-env.sh
	cat > conf/spark-env.sh <<-EOF
SPARK_LOG_DIR=/var/log/spark
SPARK_PID_DIR=/var/run/spark
SPARK_LOCAL_DIRS=/data/spark
SPARK_WORKER_MEMORY=200m
SPARK_WORKER_DIR=/data/spark
EOF

	dodir "${INSTALL_DIR}"
	diropts -m770 -o spark -g hadoop
	dodir /var/log/"${MY_PN}"
	dodir /data/"${MY_PN}"
	mv "${S}"/* "${D}${INSTALL_DIR}"
	chown -Rf root:hadoop "${D}${INSTALL_DIR}"

	# conf symlink
	dosym ${INSTALL_DIR}/conf /etc/spark

	cat > 99spark <<-EOF
SPARK_HOME="${INSTALL_DIR}"
SPARK_CONF_DIR="/etc/spark"
PATH="${INSTALL_DIR}/bin"
EOF
	doenvd 99spark

	# init scripts
	newinitd "${FILESDIR}"/"${MY_PN}.initd" "${MY_PN}.initd"
	dosym  /etc/init.d/"${MY_PN}.initd" /etc/init.d/"${MY_PN}-worker"
	if [ `egrep -c "^[0-9].*${HOSTNAME}.*#.* sparkmaster" /etc/hosts` -eq 1 ] ; then
		   dosym  /etc/init.d/"${MY_PN}.initd" /etc/init.d/"${MY_PN}-master"
	fi
}
