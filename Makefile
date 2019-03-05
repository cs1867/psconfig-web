PACKAGE=perfsonar-psconfig-web-admin
ROOTPATH=/usr/lib/perfsonar/psconfig-web-admin
CONFIGPATH=${ROOTPATH}/etc
#LIBPATH=/usr/lib/perfsonar/lib
#GRAPHLIBPATH=/usr/lib/perfsonar/psconfig-web/lib
PERFSONAR_AUTO_VERSION=4.1.6
PERFSONAR_AUTO_RELNUM=1
VERSION=${PERFSONAR_AUTO_VERSION}
RELEASE=${PERFSONAR_AUTO_RELNUM}

default:
	@echo No need to build the package. Just run \"make install\"

dist:
	mkdir /tmp/$(PACKAGE)-$(VERSION).$(RELEASE)
	tar ch -T MANIFEST | tar x -C /tmp/$(PACKAGE)-$(VERSION).$(RELEASE)
	tar czf $(PACKAGE)-$(VERSION).$(RELEASE).tar.gz -C /tmp $(PACKAGE)-$(VERSION).$(RELEASE)
	rm -rf /tmp/$(PACKAGE)-$(VERSION).$(RELEASE)

install:
	mkdir -p ${ROOTPATH}
	tar ch --exclude=etc/* --exclude=*spec --exclude=dependencies --exclude=MANIFEST --exclude=LICENSE --exclude=Makefile -T MANIFEST | tar x -C ${ROOTPATH}
	for i in `cat MANIFEST | grep ^etc/ | sed "s/^etc\///"`; do  mkdir -p `dirname $(CONFIGPATH)/$${i}`; if [ -e $(CONFIGPATH)/$${i} ]; then install -m 640 -c etc/$${i} $(CONFIGPATH)/$${i}.new; else install -m 640 -c etc/$${i} $(CONFIGPATH)/$${i}; fi; done
	sed -i 's:.RealBin/\.\./lib:${LIBPATH}:g' ${ROOTPATH}/cgi-bin/*
	sed -i 's:.RealBin/lib:${GRAPHLIBPATH}:g' ${ROOTPATH}/cgi-bin/*

rpm:
	admin pub

admin:
	rpmbuild -bs perfsonar-psconfig-web-admin.spec

pub:
	rpmbuild -bs perfsonar-psconfig-web-pub.spec


# These tests will have to be done differently, since this project uses nodejs instead of perl

#test:
#	    PERL_DL_NONLAZY=1 /usr/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0)" t/*.t

#cover:
#	    cover -test

#test_jenkins:
#	    mkdir -p tap_output
#		    PERL5OPT=-MDevel::Cover prove t/ --archive tap_output/
