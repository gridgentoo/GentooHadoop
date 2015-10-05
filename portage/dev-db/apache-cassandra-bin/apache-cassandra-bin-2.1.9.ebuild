# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=4
inherit eutils user

DESCRIPTION="The Apache Cassandra database is the right choice when you need
scalability and high availability without compromising performance."
HOMEPAGE="http://cassandra.apache.org/"
SRC_URI="mirror://apache/cassandra/${PV}/apache-cassandra-${PV}-bin.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="
	>=virtual/jdk-1.6
	"
RDEPEND=""


S="${WORKDIR}/apache-cassandra-${PV}"
INSTALL_DIR="/opt/cassandra"

pkg_setup() {
	enewgroup cassandra
	enewuser cassandra -1 /bin/bash /home/cassandra cassandra
}

src_prepare() {
	cd "${S}"
	find . \( -name \*.bat -or -name \*.exe \) -delete
	rm bin/stop-server
}

src_install() {
	# get the topology from /etc/hosts
	hostname=`uname -n`
	seeds=`egrep "^[0-9].*#.* seed" /etc/hosts | awk '{print $1}' `
	[[ -n $seeds ]] && seeds=`echo ${seeds} | sed 's/ /,/g' `
	sandbox=`egrep -c "^[0-9].*#.* sandbox" /etc/hosts`

	insinto ${INSTALL_DIR}
	# update storage dir
	sed -e "s|cassandra_storagedir=\"\$CASSANDRA_HOME/data\"|cassandra_storagedir=\"/data/cassandra/\"|g" \
		-i bin/cassandra.in.sh || die
	# update JVM mem for sandbox
	if [ $sandbox -ne 0 ] ; then
		sed -e "1iexport MAX_HEAP_SIZE=200M" -i conf/cassandra-env.sh || die
		sed -e "2iexport HEAP_NEWSIZE=200M" -i conf/cassandra-env.sh
	fi
	# update yaml for cluster case
	sed -e "s|listen_address: localhost|# listen_address: not used|" \
		-e "s|# listen_interface: .*|listen_interface: eth0|" -i conf/cassandra.yaml || die
	[[ -n $seeds ]] && sed -e  "s|seeds: .*|seeds: \"${seeds}\"|" -i conf/cassandra.yaml || die

	doins -r bin conf interface lib pylib tools

	for i in bin/* ; do
		if [[ $i == *.in.sh ]]; then
			continue
		fi
		fperms 755 ${INSTALL_DIR}/${i}
		make_wrapper "$(basename ${i})" "${INSTALL_DIR}/${i}"
	done

	dodir /data/cassandra
	dodir /var/tmp/cassandra
	dodir /var/log/cassandra
	fowners -R cassandra:cassandra ${INSTALL_DIR}
	fowners cassandra:cassandra /data/cassandra /var/tmp/cassandra /var/log/cassandra
	dosym /var/log/cassandra ${INSTALL_DIR}/logs

	newinitd "${FILESDIR}/cassandra.initd" cassandra

	echo "CONFIG_PROTECT=\"${INSTALL_DIR}/conf\"" > "99cassandra"
	doenvd 99cassandra || die "doenvd failed"
}
