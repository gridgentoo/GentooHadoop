# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils java-utils-2

MY_PN="hbase"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="HBase is the Hadoop database."
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${MY_P}/${MY_P}-bin.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror binchecks"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.6
	sys-cluster/apache-hadoop-bin"
# sys-cluster/apache-zookeeper
# dev-lang/ruby


S="${WORKDIR}/${MY_P}"
INSTALL_DIR=/opt/"${MY_PN}"
DATA_DIR=/data/"${MY_PN}"

src_install() {
	# Update hbase-env.sh
	JAVA_HOME=$(java-config -g JAVA_HOME)
	sed -i -e "2iexport JAVA_HOME=${JAVA_HOME}" conf/hbase-env.sh || die "sed failed"
	sed -i -e "3iexport HBASE_LOG_DIR=/var/log/hbase"  conf/hbase-env.sh


	dodir "${INSTALL_DIR}"
	mv "${S}"/* "${D}${INSTALL_DIR}" || die "install failed"

        # make useful dirs
        diropts -m770 -o root -g hadoop
        dodir /var/log/"${MY_PN}"
        dodir /data/hbase

	# env file
	cat > 99"${PN}" <<-EOF
		PATH=${INSTALL_DIR}/bin
		CONFIG_PROTECT=${INSTALL_DIR}/conf
	EOF
	doenvd 99"${PN}" || die "doenvd failed"

	cat > "${PN}" <<-EOF
		#!/sbin/runscript
		start() {
			${INSTALL_DIR}/bin/start-hbase.sh > /dev/null
			}
		stop() {
			${INSTALL_DIR}/bin/stop-hbase.sh > /dev/null
			}
	EOF
	doinitd "${PN}" || die "doinitd failed"
}

pkg_postinst() {
	elog "For info on configuration see http://hbase.apache.org/book.html"
}

