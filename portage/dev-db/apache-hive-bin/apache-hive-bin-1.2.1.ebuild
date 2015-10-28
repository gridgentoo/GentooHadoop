# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils

MY_PN="hive"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="High-level language and platform for analyzing large data sets"
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${MY_P}/apache-${MY_P}-bin.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror binchecks"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.6
	sys-cluster/apache-hadoop-bin"

S="${WORKDIR}/apache-${MY_P}-bin"
INSTALL_DIR="/opt/${MY_PN}"

src_install() {
	insinto "${INSTALL_DIR}"
	mv "${S}"/{bin,lib,scripts,examples} "${D}${INSTALL_DIR}"
	chown -Rf root:hadoop "${D}${INSTALL_DIR}"

	cat > 99"${MY_PN}" <<EOF
HIVE_HOME="${INSTALL_DIR}"
PATH="${INSTALL_DIR}/bin"
HIVE_CONF_DIR="/opt/hadoop"
EOF
	doenvd 99"${MY_PN}"

	#sed -e 's/org.apache.hadoop.metrics.jvm.EventCounter/org.apache.hadoop.log.metrics.EventCounter/g' -i conf/*log4j.properties || die
	#doins conf/*
	dodoc README.txt RELEASE_NOTES.txt
}
