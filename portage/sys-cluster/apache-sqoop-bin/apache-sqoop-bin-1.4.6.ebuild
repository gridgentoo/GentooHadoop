# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

MY_PN="sqoop"
MY_PN_SUFFIX=".bin__hadoop-2.0.4-alpha"

DESCRIPTION="Tool designed for efficiently transferring bulk data between Apache Hadoop and structured datastores such as relational databases"
HOMEPAGE="http://sqoop.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${PV}/${MY_PN}-${PV}${MY_PN_SUFFIX}.tar.gz"


LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="sys-cluster/apache-hadoop-bin"
RDEPEND="$DEPEND"

S="${WORKDIR}/${MY_PN}-${PV}${MY_PN_SUFFIX}"
INSTALL_DIR=/opt/${MY_PN}-${PV}

src_install() {
	dodir "${INSTALL_DIR}"
	mv "${S}"/* "${D}${INSTALL_DIR}"
	chown -Rf root:hadoop "${D}${INSTALL_DIR}"
	dosym "${INSTALL_DIR}" "/opt/${MY_PN}"
}
