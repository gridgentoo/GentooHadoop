# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils

MY_PN="pig"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="High-level language and platform for analyzing large data sets"
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${MY_P}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror binchecks"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.6
	sys-cluster/apache-hadoop-bin"

S="${WORKDIR}/${MY_P}"

src_install() {
	dobin bin/pig

	insinto /opt/"${MY_PN}"
	mv "${S}"/{contrib,lib,scripts,src/packages/templates,test,*.jar} "${D}"/opt/"${MY_PN}"

	insinto /etc/"${MY_PN}"
	doins conf/*
	dosbin src/packages/*.sh

	cat > 99pig <<-EOF
PIG_HOME="/opt/pig"
PIG_CLASSPATH="/opt/hadoop"
EOF
	[ `egrep -c "^[0-9].*#.* sandbox" /etc/hosts` -ne 0 ] && echo "PIG_HEAPSIZE=200" >> 99pig
	doenvd 99pig
	#dodoc README.txt RELEASE_NOTES.txt CHANGES.txt
	#dohtml -r docs/*
}
