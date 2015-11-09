# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit user java-utils-2

MY_PN="sqoop"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Software framework for fast cluster computing"
HOMEPAGE="http://spark.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${PV}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="scala"

DEPEND=""

RDEPEND="sys-cluster/apache-hadoop-bin"


S="${WORKDIR}/${MY_P}"
INSTALL_DIR=/opt/${MY_PN}

src_install() {
	dodir "${INSTALL_DIR}"
	mv "${S}"/* "${D}${INSTALL_DIR}"
	chown -Rf root:hadoop "${D}${INSTALL_DIR}"
}
