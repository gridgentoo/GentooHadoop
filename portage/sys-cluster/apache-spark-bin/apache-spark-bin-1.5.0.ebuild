# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

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


S="${WORKDIR}/${MY_P}"
INSTALL_DIR=/opt/hive

src_install() {
	dodir "${INSTALL_DIR}"
        mv "${S}"/* "${D}${INSTALL_DIR}" || die "install failed"
}

pkg_postinst() {
    elog "For info on configuration see https://cwiki.apache.org/confluence/display/Hive/Home"
}


