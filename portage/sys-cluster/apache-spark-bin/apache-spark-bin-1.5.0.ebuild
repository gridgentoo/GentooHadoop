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
	dodir "${INSTALL_DIR}"
	mv "${S}"/* "${D}${INSTALL_DIR}"

	cat > 99spark <<-EOF
SPARK_HOME="${INSTALL_DIR}"
SPARK_CONF_DIR="/etc/hadoop"
PATH="${INSTALL_DIR}/bin"
EOF
	doenvd 99spark

	# init scripts
	newinitd "${FILESDIR}"/"${MY_PN}" "${MY_PN}"
	if [ `egrep -c "^[0-9].*${HOSTNAME}.*#.* "sparkmaster" /etc/hosts` -eq 1 ] ; then
		   dosym  /etc/init.d/"${MY_PN}" /etc/init.d/"${MY_PN}"-"master"
	fi
}
