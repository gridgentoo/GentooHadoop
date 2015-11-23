# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit user

MY_PN="cassandra"

DESCRIPTION="The Apache Cassandra database is the right choice when you need
scalability and high availability without compromising performance."
HOMEPAGE="http://cassandra.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${PV}/apache-${MY_PN}-${PV}-bin.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="jre"
RDEPEND="$DEPEND"


S="${WORKDIR}/apache-${MY_PN}-${PV}-bin"
INSTALL_DIR="/opt/${MY_PN}-${PV}"

pkg_setup() {
	enewgroup hadoop
	enewuser cassandra -1 /bin/bash /home/cassandra hadoop
}


src_install() {
	# get the topology from /etc/hosts
	hostname=`uname -n`
	seeds=`egrep "^[0-9].*#.* cassandraseed" /etc/hosts | awk '{print $1}' `
	[[ -n $seeds ]] && seeds=`echo ${seeds} | sed 's/ /,/g' `
	sandbox=`egrep -c "^[0-9].*#.* sandbox" /etc/hosts`

	insinto ${INSTALL_DIR}

	find . \( -name \*.bat -or -name \*.exe -or -name \*.dll -or -name \*.ps1 \) -delete
	rm -f bin/stop-server
	rm -f lib/sigar-bin/*solaris* lib/sigar-bin/*ppc* lib/sigar-bin/*s390* lib/sigar-bin/*ia64* ib/sigar-bin/*freebsd*

	# update storage dir
	# sed -e "s|cassandra_storagedir=\"\$CASSANDRA_HOME/data\"|cassandra_storagedir=\"/data/cassandra/\"|g" -i bin/cassandra.in.sh || die

	# update JVM mem for sandbox
	if [ $sandbox -ne 0 ] ; then
		sed -e "1iexport MAX_HEAP_SIZE=256M\nexport HEAP_NEWSIZE=256M" -i conf/cassandra-env.sh || die
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

	dodir /var/log/cassandra
	fowners cassandra:hadoop /var/log/cassandra
	fowners -R cassandra:hadoop ${INSTALL_DIR}
	dosym /var/log/cassandra ${INSTALL_DIR}/logs

	newinitd ${FILESDIR}/cassandra cassandra

	# echo "CONFIG_PROTECT=\"${INSTALL_DIR}/conf\"" > "99cassandra"
	# doenvd 99cassandra || die "doenvd failed"

	dosym ${INSTALL_DIR} /opt/${MY_PN}
}
